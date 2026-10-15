"""Clasificador de tabla: regresión logística (tablas × 768) sobre el vector de EmbeddingGemma
de la pregunta. Se entrena en segundos en CPU con las preguntas generadas (datos/gen-*.json) y
las de ejemplo de las fichas; las baterías de tools/chat/evaluacion solo se usan para medir.

    python entrenar-clasificador.py --raiz <repo con build/chat/catalogo.json> [--salida datos/clasificador.json]
           [--medir datos/vectores-preguntas-validacion5.json,...] [--l2 1e-4] [--epocas 300]

Salida en el formato de clasificador.mjs (pesos Int8 por fila con su escala).
"""
import argparse, base64, json, math, os, random
import numpy as np
import torch

ap = argparse.ArgumentParser()
ap.add_argument("--raiz", default=None)
ap.add_argument("--catalogo", default=None, help="ruta del catálogo (por defecto <raiz>/build/chat/catalogo.json)")
ap.add_argument("--datos", default=os.path.join(os.path.dirname(__file__), "datos"))
ap.add_argument("--salida", default=None)
ap.add_argument("--medir", default="")
ap.add_argument("--l2", type=float, default=1e-4)
ap.add_argument("--epocas", type=int, default=300)
ap.add_argument("--lr", type=float, default=0.05)
ap.add_argument("--reserva", type=float, default=0.1, help="parte de las preguntas generadas para validar")
ap.add_argument("--sin-fichas", action="store_true")
ap.add_argument("--todo", action="store_true", help="entrena con todo (sin reserva) tras elegir hiperparámetros")
ap.add_argument("--semilla", type=int, default=0)
ap.add_argument("--dims", type=int, default=256, help="primeras dimensiones (Matryoshka), como el vector que ya calcula el chat")
a = ap.parse_args()
torch.manual_seed(a.semilla); random.seed(a.semilla)

catalogo = json.load(open(a.catalogo or os.path.join(a.raiz, "build/chat/catalogo.json"), encoding="utf8"))
tablas = [t["nombre"] for t in catalogo["tablas"] if (t.get("semantica") or {}).get("usar") is not False]
idx = {t: i for i, t in enumerate(tablas)}


def cargar(ruta):
    d = json.load(open(ruta, encoding="utf8"))
    v = np.frombuffer(base64.b64decode(d["vecs"]), dtype=np.float32).reshape(-1, d["dims"])[:, : a.dims]
    return d["items"], v / np.linalg.norm(v, axis=1, keepdims=True)


items, V = cargar(os.path.join(a.datos, "vectores-entrenamiento.json"))
ok = [i for i, it in enumerate(items) if any(t in idx for t in it["tablas"]) and (not a.sin_fichas or it["fuente"] != "ficha")]
items = [items[i] for i in ok]; V = V[ok]

# Reserva: preguntas generadas al azar (las de las fichas siempre entrenan)
gen = [i for i, it in enumerate(items) if it["fuente"] == "gen"]
random.shuffle(gen)
reserva = set() if a.todo else set(gen[: int(len(gen) * a.reserva)])
tr = [i for i in range(len(items)) if i not in reserva]
va = sorted(reserva)


def objetivo(it):
    y = np.zeros(len(tablas), dtype=np.float32)
    validas = [idx[t] for t in it["tablas"] if t in idx]
    # La principal pesa más que las que también valen
    y[validas[0]] = 1.0
    for j in validas[1:]:
        y[j] = 0.5
    return y / y.sum()


X = torch.tensor(V); Y = torch.tensor(np.stack([objetivo(it) for it in items]))
W = torch.zeros(len(tablas), X.shape[1], requires_grad=True)
b = torch.zeros(len(tablas), requires_grad=True)
opt = torch.optim.Adam([W, b], lr=a.lr)
xtr, ytr = X[tr], Y[tr]
for ep in range(a.epocas):
    opt.zero_grad()
    logits = xtr @ W.T + b
    loss = -(ytr * torch.log_softmax(logits, -1)).sum(-1).mean() + a.l2 * (W ** 2).sum()
    loss.backward(); opt.step()


def evaluar(Xe, its, nombre):
    with torch.no_grad():
        l = Xe @ W.T + b
    orden = torch.argsort(l, -1, descending=True)[:, :6].numpy()
    a1 = a3 = a6 = 0
    for k, it in enumerate(its):
        buenas = {idx[t] for t in it["tablas"] if t in idx}
        pos = next((p for p, j in enumerate(orden[k]) if j in buenas), None)
        a1 += pos == 0; a3 += pos is not None and pos < 3; a6 += pos is not None
    n = max(len(its), 1)
    print(f"  {nombre:40s} n={len(its):4d}  @1 {a1/n:5.1%}  @3 {a3/n:5.1%}  @6 {a6/n:5.1%}")
    return l


# Temperatura: la que mejor calibra la reserva (log-verosimilitud)
T = 1.0
if va:
    with torch.no_grad():
        lv = X[va] @ W.T + b
        mejor = None
        for t in [0.5, 0.75, 1, 1.5, 2, 3, 4, 6, 8]:
            nll = -(Y[va] * torch.log_softmax(lv / t, -1)).sum(-1).mean().item()
            if mejor is None or nll < mejor[0]:
                mejor = (nll, t)
        T = mejor[1]

print(f"tablas {len(tablas)} · entrenamiento {len(tr)} · reserva {len(va)} · l2 {a.l2} · temperatura {T}")
if va:
    evaluar(X[va], [items[i] for i in va], "reserva (generadas)")
for ruta in [r for r in a.medir.split(",") if r]:
    its, Ve = cargar(ruta)
    evaluar(torch.tensor(Ve), its, os.path.basename(ruta))

if a.salida:
    with torch.no_grad():
        Wn = W.detach().numpy()
        escala = np.abs(Wn).max(1) / 127.0 + 1e-12
        q = np.clip(np.round(Wn / escala[:, None]), -127, 127).astype(np.int8)
    json.dump({"dims": int(X.shape[1]), "tablas": tablas, "pesos": base64.b64encode(q.tobytes()).decode(),
               "escala": [float(x) for x in escala], "sesgo": [float(x) for x in b.detach().numpy()], "temperatura": T,
               "generado": "entrenar-clasificador.py", "ejemplos": len(tr)}, open(a.salida, "w"))
    print("->", a.salida, f"{os.path.getsize(a.salida)/1e3:.0f} kB")
