#!/usr/bin/env python3
import os,re,subprocess,sys,tempfile
from pathlib import Path
from common import ROOT,CONFIG,dc,sha,verify
if len(sys.argv)!=3 or sys.argv[2]!='--accept-restored-content':raise SystemExit('Uso: python3 scripts/restore.py /ruta/respaldo --accept-restored-content')
p=verify(sys.argv[1])
for n in CONFIG:
    if n in ['.env','certs/ca.crt']:continue
    if not (ROOT/n).is_file() or sha(ROOT/n)!=sha(p/n):raise SystemExit('Kit/configuracion distinto: '+n)
if dc('ps','--services','--status','running',capture_output=True,text=True).stdout.strip():raise SystemExit('Destino debe estar completamente detenido')
dc('run','--rm','--no-deps','-T','-e','BOOTSTRAP_MODE=true','preflight')
count=dc('run','--rm','--no-deps','-T','--entrypoint','psql','dbtools','--no-psqlrc','-Atc',"SELECT count(*) FROM pg_tables WHERE schemaname='public'",capture_output=True,text=True).stdout.strip()
if count!='0':raise SystemExit('public no esta vacio; no se sobrescribe')
for folder in ['/files']:
    if dc('run','--rm','--no-deps','-T','--entrypoint','find','filetools',folder,'-mindepth','1','-print','-quit',capture_output=True,text=True).stdout.strip():raise SystemExit('Volumen ocupado: '+folder)
with (p/'public.dump').open('rb') as f:toc=dc('run','--rm','--no-deps','-T','--entrypoint','pg_restore','dbtools','--list',stdin=f,stdout=subprocess.PIPE).stdout.decode()
lines=[s for s in toc.splitlines() if not re.match(r'^\d+;\s+\d+\s+\d+\s+SCHEMA\s+-\s+public(?:\s|$)',s)]
with tempfile.TemporaryDirectory(prefix='hefesto-inventario-restore-') as tmp:
    file=Path(tmp)/'restore.list';file.write_text('\n'.join(lines)+'\n');os.chmod(tmp,0o755);os.chmod(file,0o644)
    with (p/'public.dump').open('rb') as f:dc('run','--rm','--no-deps','-T','-v',tmp+':/restore:ro','--entrypoint','pg_restore','dbtools','--exit-on-error','--single-transaction','--no-owner','--no-acl','--use-list=/restore/restore.list','--dbname=postgres',stdin=f)
for name,folder in [('files.tar.gz','/files')]:
    with (p/name).open('rb') as f:dc('run','--rm','--no-deps','-T','--entrypoint','tar','filetools','-xzf','-','-C',folder,stdin=f)

dc('run','--rm','--no-deps','-T','permissions')
print('Inventario y archivos recuperados; app detenida. Revisar destino antes de iniciar.')
