import os
from pathlib import Path
p=Path(__file__).resolve().parents[1]
fd=os.open(p/'.env',os.O_CREAT|os.O_EXCL|os.O_WRONLY,0o600)
with os.fdopen(fd,'w') as f:f.write((p/'.env.example').read_text())
print('Editar .env y copiar CA a certs/ca.crt; no hay credenciales incluidas.')
