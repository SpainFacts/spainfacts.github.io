"""Afina un decisor (LoRA) con las decisiones de datos/trazas.jsonl: entropía cruzada sobre los
logits de las letras A, B, C... en la posición «Answer: (», como la receta de Mapika/decider,
con el prompt exacto de promptDecision (src/lib/chat/decision.js).

    python entrenar-decisor.py --modelo google/gemma-4-E2B-it --salida runs/gemma4-e2b [--epocas 1] [--rango 16]

Se reserva una de cada 10 preguntas (por id) para validar; las baterías de
tools/chat/evaluacion no se usan aquí.
"""
import argparse, hashlib, json, math, os, random, time
import torch
from transformers import AutoModelForCausalLM, AutoTokenizer

ap = argparse.ArgumentParser()
ap.add_argument("--modelo", required=True)
ap.add_argument("--trazas", default=os.path.join(os.path.dirname(__file__), "datos", "trazas.jsonl"))
ap.add_argument("--salida", required=True)
ap.add_argument("--epocas", type=float, default=1.0)
ap.add_argument("--lr", type=float, default=1e-4)
ap.add_argument("--rango", type=int, default=16)
ap.add_argument("--acumular", type=int, default=16)
ap.add_argument("--barajar", type=float, default=0.5, help="probabilidad de barajar el orden de las opciones")
ap.add_argument("--max-tokens", type=int, default=1536)
ap.add_argument("--limite", type=int, default=0)
ap.add_argument("--solo-medir", action="store_true")
ap.add_argument("--lora", default=None, help="adaptador ya entrenado (con --solo-medir)")
ap.add_argument("--semilla", type=int, default=0)
ap.add_argument("--reanudar", default=None, help="adaptador guardado desde el que seguir")
ap.add_argument("--desde-paso", type=int, default=0, help="paso en que se guardó (mismo orden de datos con la misma semilla)")
a = ap.parse_args()
random.seed(a.semilla); torch.manual_seed(a.semilla)
os.makedirs(a.salida, exist_ok=True)
log = open(os.path.join(a.salida, "registro.txt"), "a", encoding="utf8")


def p(*x):
    s = " ".join(str(y) for y in x); print(s, flush=True); log.write(s + "\n"); log.flush()


p("[args]", json.dumps(vars(a)))
dispositivo = "cuda" if torch.cuda.is_available() else "cpu"
tok = AutoTokenizer.from_pretrained(a.modelo)
modelo = AutoModelForCausalLM.from_pretrained(a.modelo, dtype=torch.bfloat16).to(dispositivo)
BOS = tok.bos_token if (tok.bos_token and "gemma" in (modelo.config.model_type or "")) else ""
LETRAS = [tok.encode(chr(65 + i), add_special_tokens=False)[0] for i in range(26)]


def prompt(d, orden):
    letras = "\n".join(f"({chr(65 + k)}) {d['opciones'][i]}" for k, i in enumerate(orden))
    return f"Context:\n{d['contexto']}\n\nQuestion: {d['pregunta']}\nOptions:\n{letras}\nAnswer: ("


def reservada(d):
    return int(hashlib.md5(d["id"].encode()).hexdigest(), 16) % 10 == 0


datos = [json.loads(l) for l in open(a.trazas, encoding="utf8")]
datos = [d for d in datos if 2 <= len(d["opciones"]) <= 26]
if a.limite:
    random.shuffle(datos); datos = datos[: a.limite]
tr = [d for d in datos if not reservada(d)]
va = [d for d in datos if reservada(d)]
p(f"decisiones: entrenamiento {len(tr)} · reserva {len(va)} · por tipo " + json.dumps({t: sum(d['tipo'] == t for d in datos) for t in sorted({d['tipo'] for d in datos})}))


def logits_letras(texto, n):
    ids = tok(BOS + texto, return_tensors="pt", add_special_tokens=False, truncation=True, max_length=a.max_tokens).to(dispositivo)
    out = modelo(**ids, logits_to_keep=1)
    return out.logits[0, -1, LETRAS[:n]].float()


@torch.no_grad()
def medir(conjunto, nombre):
    modelo.eval()
    bien, por = 0, {}
    for d in conjunto:
        orden = list(range(len(d["opciones"])))
        l = logits_letras(prompt(d, orden), len(orden))
        ok = int(l.argmax().item() == d["oro"])
        bien += ok
        por.setdefault(d["tipo"], [0, 0]); por[d["tipo"]][0] += ok; por[d["tipo"]][1] += 1
    p(f"[medida] {nombre}: {bien}/{len(conjunto)} ({bien/max(len(conjunto),1):.1%}) · " + " ".join(f"{k} {v[0]}/{v[1]}" for k, v in sorted(por.items())))
    modelo.train()
    return bien / max(len(conjunto), 1)


if a.lora:
    from peft import PeftModel
    modelo = PeftModel.from_pretrained(modelo, a.lora)
if a.solo_medir:
    medir(va, "reserva"); raise SystemExit

if not a.reanudar:
    medir(va, "reserva antes")
from peft import LoraConfig, get_peft_model
# Solo las capas de texto (Gemma 4 trae también visión y audio)
objetivos = r".*language_model.*\.(q_proj|k_proj|v_proj|o_proj|gate_proj|up_proj|down_proj)$" if "gemma" in modelo.config.model_type or hasattr(modelo.config, "text_config") else ["q_proj", "k_proj", "v_proj", "o_proj", "gate_proj", "up_proj", "down_proj"]
if a.reanudar:
    from peft import PeftModel
    modelo = PeftModel.from_pretrained(modelo, a.reanudar, is_trainable=True)
else:
    modelo = get_peft_model(modelo, LoraConfig(r=a.rango, lora_alpha=2 * a.rango, lora_dropout=0.05, target_modules=objetivos))
modelo.print_trainable_parameters()
modelo.gradient_checkpointing_enable() if hasattr(modelo, "gradient_checkpointing_enable") else None
modelo.enable_input_require_grads()
modelo.train()
opt = torch.optim.AdamW([q for q in modelo.parameters() if q.requires_grad], lr=a.lr, weight_decay=0.0)
pasos_total = math.ceil(len(tr) * a.epocas / a.acumular)
calentar = max(10, pasos_total // 20)


def lr_en(s):
    if s < calentar:
        return a.lr * s / calentar
    return a.lr * 0.5 * (1 + math.cos(math.pi * min(1.0, (s - calentar) / max(1, pasos_total - calentar))))


paso, micro, acc, t0 = a.desde_paso, 0, 0.0, time.time()
orden_datos = []
while len(orden_datos) < len(tr) * a.epocas:
    o = tr[:]; random.shuffle(o); orden_datos += o
orden_datos = orden_datos[: int(len(tr) * a.epocas)][a.desde_paso * a.acumular :]
for d in orden_datos:
    orden = list(range(len(d["opciones"])))
    if random.random() < a.barajar:
        random.shuffle(orden)
    oro = orden.index(d["oro"])
    l = logits_letras(prompt(d, orden), len(orden))
    perdida = torch.nn.functional.cross_entropy(l[None], torch.tensor([oro], device=dispositivo))
    (perdida / a.acumular).backward()
    acc += perdida.item(); micro += 1
    if micro % a.acumular == 0:
        for g in opt.param_groups:
            g["lr"] = lr_en(paso)
        torch.nn.utils.clip_grad_norm_([q for q in modelo.parameters() if q.requires_grad], 1.0)
        opt.step(); opt.zero_grad(set_to_none=True); paso += 1
        if paso % 10 == 0:
            el = time.time() - t0
            p(f"[paso] {paso}/{pasos_total} pérdida {acc/micro:.4f} · {el/60:.1f} min · faltan {(pasos_total-paso)*el/max(paso-a.desde_paso,1)/60:.0f} min")
            acc, micro = 0.0, 0
        if paso % 200 == 0:
            modelo.save_pretrained(os.path.join(a.salida, "lora"))
modelo.save_pretrained(os.path.join(a.salida, "lora"))
p("[guardado]", os.path.join(a.salida, "lora"))
medir(va, "reserva después")
