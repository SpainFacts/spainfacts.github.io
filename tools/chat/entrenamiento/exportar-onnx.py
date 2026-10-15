"""Lleva un decisor Qwen3.5-0.8B (Mapika/decider-0.8b, con o sin LoRA nuestro) al navegador sin
reexportar el grafo: se toma el ONNX de onnx-community/Qwen3.5-0.8B-ONNX (el que ya se ha
probado en el navegador con WebGPU y WASM) y se sustituyen sus pesos por los del decisor.
Así el grafo, y con él los operadores que necesita onnxruntime-web, no cambia.

    python exportar-onnx.py --referencia <carpeta con los ONNX de onnx-community> --modelo Mapika/decider-0.8b
                            [--lora runs/x/lora] --salida <carpeta> [--variantes q4f16,q4]

Pasos:
1. Cada peso del ONNX fp32 se casa con su tensor de Hugging Face (Qwen/Qwen3.5-0.8B, del que se
   exportó) y se averigua la transformación (traspuesta, 1+w, -exp(w)...) comprobándola con los
   números: si no reproduce el ONNX, se para.
2. Se aplica esa transformación a los pesos del decisor (con el LoRA fusionado).
3. En los ONNX cuantizados (MatMulNBits de 4 bits, bloque 32, con punto cero) se cuantiza cada
   matriz con el mismo esquema; antes se comprueba que el esquema reproduce los pesos originales.
4. embed_tokens va en fp16 (el q4 usa GatherBlockQuantized, que onnxruntime-web no tiene en WASM).
"""
import argparse, json, os, re, shutil
import numpy as np
import onnx
from onnx import numpy_helper
import torch

ap = argparse.ArgumentParser()
ap.add_argument("--referencia", required=True)
ap.add_argument("--original", default="Qwen/Qwen3.5-0.8B", help="modelo de HF del que se exportó la referencia")
ap.add_argument("--modelo", default="Mapika/decider-0.8b")
ap.add_argument("--lora", default=None)
ap.add_argument("--salida", required=True)
ap.add_argument("--variantes", default="q4f16,q4")
a = ap.parse_args()
R = a.referencia
os.makedirs(os.path.join(a.salida, "onnx"), exist_ok=True)


def tensores_hf(nombre, lora=None):
    from transformers import AutoModelForCausalLM
    m = AutoModelForCausalLM.from_pretrained(nombre, dtype=torch.float32)
    if lora:
        from peft import PeftModel
        m = PeftModel.from_pretrained(m, lora).merge_and_unload()
    sd = {k: v.detach().float().numpy() for k, v in m.state_dict().items()}
    # Quitar el prefijo del modelo multimodal (model.language_model.* -> model.*)
    return {re.sub(r"^model\.language_model\.", "model.", k): v for k, v in sd.items()}


print("cargando pesos de", a.original, "y", a.modelo, "+", a.lora)
orig = tensores_hf(a.original)
nuevo = tensores_hf(a.modelo, a.lora)
if "lm_head.weight" not in nuevo:
    nuevo["lm_head.weight"] = nuevo["model.embed_tokens.weight"]
if "lm_head.weight" not in orig:
    orig["lm_head.weight"] = orig["model.embed_tokens.weight"]


def clave_hf(n):
    """Nombre del ONNX -> nombre de Hugging Face"""
    m = re.match(r"model\.layers\.(\d+)\.(.*)", n)
    if n == "lm_head.MatMul.weight":
        return "lm_head.weight"
    if not m:
        return None
    i, resto = m.groups()
    if resto == "final_norm_layernorm.weight":
        return "model.norm.weight"
    resto = (resto.replace("gdn.", "linear_attn.").replace("attn.", "self_attn.").replace(".MatMul.weight", ".weight")
             .replace(".layernorm.weight", ".weight").replace("A_neg_exp", "A_log").replace("conv1d.weight_3d", "conv1d.weight"))
    resto = resto.replace("linear_self_attn.", "linear_attn.")
    return f"model.layers.{i}.{resto}"


TRANSFORMACIONES = {
    "igual": lambda w, forma: w.reshape(forma),
    "traspuesta": lambda w, forma: w.T.reshape(forma),
    "uno_mas": lambda w, forma: (1.0 + w).reshape(forma),
    "menos_exp": lambda w, forma: (-np.exp(w)).reshape(forma),
}

# 1. Transformación de cada peso, comprobada con los números
ref32 = onnx.load(os.path.join(R, "decoder_model_merged.onnx"))  # con sus datos externos
receta = {}
for t in ref32.graph.initializer:
    if t.name.startswith("/model/constants") or t.name == "model.inv_freq":
        continue
    k = clave_hf(t.name)
    if k not in orig:
        raise SystemExit(f"sin pareja en HF: {t.name} -> {k}")
    v = numpy_helper.to_array(t).astype(np.float32)
    mejor = None
    for nombre, f in TRANSFORMACIONES.items():
        try:
            err = float(np.abs(f(orig[k], v.shape) - v).max())
        except ValueError:
            continue
        if mejor is None or err < mejor[1]:
            mejor = (nombre, err)
    escala = float(np.abs(v).max()) + 1e-6
    if mejor is None or mejor[1] > 1e-2 * escala:
        raise SystemExit(f"no encuentro la transformación de {t.name} ({k}): {mejor}")
    receta[t.name] = (k, mejor[0], list(v.shape))
print(f"{len(receta)} pesos casados; transformaciones:", {x: sum(1 for r in receta.values() if r[1] == x) for x in TRANSFORMACIONES})
nuevos32 = {n: TRANSFORMACIONES[tr](nuevo[k], forma).astype(np.float32) for n, (k, tr, forma) in receta.items()}
del ref32


# 3. Cuantización MatMulNBits (4 bits, bloque 32, asimétrica con punto cero)
def cuantizar(W, bloque=32):
    """W [K, N] -> (B uint8 [N, K/bloque, bloque/2], escalas [N, K/bloque], zp uint8 [N, ceil(K/bloque/2)])"""
    K, N = W.shape
    nb = (K + bloque - 1) // bloque
    Wp = np.zeros((nb * bloque, N), np.float32); Wp[:K] = W
    Wb = Wp.T.reshape(N, nb, bloque)
    mn = np.minimum(Wb.min(-1), 0.0); mx = np.maximum(Wb.max(-1), 0.0)
    escala = (mx - mn) / 15.0
    escala[escala == 0] = 1.0
    zp = np.clip(np.round(-mn / escala), 0, 15).astype(np.uint8)
    q = np.clip(np.round(Wb / escala[..., None]) + zp[..., None], 0, 15).astype(np.uint8)
    B = (q[..., 0::2] | (q[..., 1::2] << 4)).astype(np.uint8)
    zp2 = np.zeros((N, (nb + 1) // 2), np.uint8)
    zp2[:, : nb // 2 + nb % 2] |= zp[:, 0::2]
    zp2[:, : nb // 2] |= zp[:, 1::2] << 4
    return B, escala, zp2


def descuantizar(B, escala, zp2, K):
    N, nb, _ = B.shape
    q = np.empty((N, nb, B.shape[2] * 2), np.float32)
    q[..., 0::2] = B & 15; q[..., 1::2] = B >> 4
    zp = np.empty((N, zp2.shape[1] * 2), np.float32)
    zp[:, 0::2] = zp2 & 15; zp[:, 1::2] = zp2 >> 4
    w = (q - zp[:, :nb, None]) * escala[..., None].astype(np.float32)
    return w.reshape(N, -1)[:, :K].T


def parchear(variante):
    nombre = f"decoder_model_merged_{variante}.onnx"
    m = onnx.load(os.path.join(R, nombre))
    ini = {t.name: t for t in m.graph.initializer}
    hechos, comprobados = 0, 0
    for nodo in m.graph.node:
        if nodo.op_type != "MatMulNBits":
            continue
        nb_, ne_, nz_ = nodo.input[1], nodo.input[2], nodo.input[3]
        base = nb_[: -len("_quant")]
        fp = next((n for n in receta if n.replace(".", "_") == base), None)
        if fp is None:
            raise SystemExit(f"sin peso fp32 para {nb_}")
        B0 = numpy_helper.to_array(ini[nb_]); E0 = numpy_helper.to_array(ini[ne_]); Z0 = numpy_helper.to_array(ini[nz_])
        K = int(next(x.i for x in nodo.attribute if x.name == "K"))
        if comprobados < 6:
            # El esquema reproduce los pesos originales: su descuantización ~ pesos fp32 de Qwen3.5
            W0 = TRANSFORMACIONES[receta[fp][1]](orig[receta[fp][0]], receta[fp][2])
            err = np.abs(descuantizar(B0, E0, Z0, K) - W0).max() / (np.abs(W0).max() + 1e-6)
            Bm, Em, Zm = cuantizar(W0)
            igual = float((Bm == B0).mean())
            print(f"  {fp}: error relativo de su q4 {err:.3f}; mi cuantización coincide en {igual:.1%} de los bytes")
            if err > 0.2:
                raise SystemExit("el formato de MatMulNBits no es el esperado")
            comprobados += 1
        B, E, Z = cuantizar(nuevos32[fp])
        ini[nb_].CopyFrom(numpy_helper.from_array(B.reshape(B0.shape), nb_))
        ini[ne_].CopyFrom(numpy_helper.from_array(E.astype(E0.dtype).reshape(E0.shape), ne_))
        ini[nz_].CopyFrom(numpy_helper.from_array(Z.reshape(Z0.shape), nz_))
        hechos += 1
    # Pesos sin cuantizar (normas, A, dt_bias, conv1d...)
    otros = 0
    for n, v in nuevos32.items():
        if n in ini:
            t = ini[n]
            dt = onnx.helper.tensor_dtype_to_np_dtype(t.data_type)
            t.CopyFrom(numpy_helper.from_array(v.astype(dt).reshape(list(t.dims)), n))
            otros += 1
    destino = os.path.join(a.salida, "onnx", nombre)
    onnx.save(m, destino, save_as_external_data=True, all_tensors_to_one_file=True, location=nombre + "_data", size_threshold=1024)
    print(f"{nombre}: {hechos} matrices cuantizadas y {otros} pesos más -> {destino}")


for v in a.variantes.split(","):
    parchear(v)

# 4. embed_tokens en fp16
e = onnx.load(os.path.join(R, "embed_tokens_fp16.onnx"))
for t in e.graph.initializer:
    if list(t.dims) == list(nuevo["model.embed_tokens.weight"].shape):
        t.CopyFrom(numpy_helper.from_array(nuevo["model.embed_tokens.weight"].astype(np.float16), t.name))
        print("embed_tokens:", t.name)
onnx.save(e, os.path.join(a.salida, "onnx", "embed_tokens_fp16.onnx"), save_as_external_data=True, all_tensors_to_one_file=True, location="embed_tokens_fp16.onnx_data", size_threshold=1024)

# Configuración y tokenizador
for f in ["config.json", "generation_config.json", "preprocessor_config.json"]:
    if os.path.exists(os.path.join(R, f)):
        shutil.copy(os.path.join(R, f), os.path.join(a.salida, f))
from transformers import AutoTokenizer
AutoTokenizer.from_pretrained(a.modelo).save_pretrained(a.salida)
json.dump({"modelo": a.modelo, "lora": a.lora, "referencia": "onnx-community/Qwen3.5-0.8B-ONNX", "variantes": a.variantes},
          open(os.path.join(a.salida, "origen.json"), "w"), indent=1)
print("hecho:", a.salida)
