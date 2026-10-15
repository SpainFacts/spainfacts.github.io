"""Servidor local de decisión para evaluar modelos de Hugging Face (base o afinados con LoRA)
con el mismo bucle que el chat (evaluar-decisor.mjs --decisor http://127.0.0.1:8765).

    python servir.py --modelo Mapika/decider-0.8b [--lora carpeta] [--puerto 8765]

POST /decidir {"prompt": "...Answer: (", "n": 6} -> {"probs": [...]}: softmax de los logits
de las letras A, B, C... en la última posición (lo mismo que leen Ollama y transformers.js).
"""
import argparse, json
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
import threading
import torch
from transformers import AutoModelForCausalLM, AutoTokenizer

ap = argparse.ArgumentParser()
ap.add_argument("--modelo", required=True)
ap.add_argument("--lora", default=None)
ap.add_argument("--puerto", type=int, default=8765)
ap.add_argument("--dispositivo", default="cuda" if torch.cuda.is_available() else "cpu")
a = ap.parse_args()

tok = AutoTokenizer.from_pretrained(a.modelo)
modelo = AutoModelForCausalLM.from_pretrained(a.modelo, dtype=torch.bfloat16).to(a.dispositivo).eval()
if a.lora:
    from peft import PeftModel
    modelo = PeftModel.from_pretrained(modelo, a.lora).merge_and_unload().eval()
LETRAS = [tok.encode(chr(65 + i), add_special_tokens=False)[0] for i in range(26)]
# Gemma necesita <bos> (el chat lo pone a mano); los tokenizadores que no lo usan no lo añaden
BOS = tok.bos_token if (tok.bos_token and "gemma" in (modelo.config.model_type or "")) else ""
cerrojo = threading.Lock()


@torch.no_grad()
def decidir(prompt, n):
    ids = tok(BOS + prompt, return_tensors="pt", add_special_tokens=False).to(a.dispositivo)
    with cerrojo:
        out = modelo(**ids, logits_to_keep=1)
    logits = out.logits[0, -1].float()
    l = logits[LETRAS[:n]]
    return torch.softmax(l, -1).tolist()


class Manejador(BaseHTTPRequestHandler):
    def do_POST(self):
        cuerpo = json.loads(self.rfile.read(int(self.headers["Content-Length"])))
        r = json.dumps({"probs": decidir(cuerpo["prompt"], cuerpo["n"])}).encode()
        self.send_response(200)
        self.send_header("Content-Type", "application/json")
        self.send_header("Content-Length", str(len(r)))
        self.end_headers()
        self.wfile.write(r)

    def log_message(self, *x):
        pass


print(f"{a.modelo}{' + ' + a.lora if a.lora else ''} en {a.dispositivo}, puerto {a.puerto}", flush=True)
ThreadingHTTPServer(("127.0.0.1", a.puerto), Manejador).serve_forever()
