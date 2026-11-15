"""Runs real headless server/client processes, then stops every process."""
import os, subprocess, time
from pathlib import Path
root=Path(__file__).resolve().parents[1]
godot=os.environ.get('GODOT_BIN','godot')
logs=root/'build';logs.mkdir(exist_ok=True)
def run_case(script, ui=False):
 log=(logs/('server-ui.log' if ui else 'server-network.log')).open('w')
 server=subprocess.Popen([godot,'--headless','--script','network/arena_server.gd','--','--port=9081'],cwd=root,stdout=log,stderr=subprocess.STDOUT)
 children=[]
 try:
  for _ in range(200):
   log.flush()
   if 'ARENA SERVER READY' in Path(log.name).read_text():break
   if server.poll() is not None:raise RuntimeError('Server exited')
   time.sleep(.025)
  if ui:
   for args in [['--host'],[]]:children.append(subprocess.Popen([godot,'--headless','--script',script,'--',*args],cwd=root,stdout=subprocess.PIPE,stderr=subprocess.STDOUT,text=True))
   for index,child in enumerate(children):
    try:output=child.communicate(timeout=25)[0]
    except subprocess.TimeoutExpired as error:
     output=error.output.decode() if isinstance(error.output,bytes) else (error.output or '')
     (logs/f'online-ui-{index}.log').write_text(output)
     raise RuntimeError(output) from error
    (logs/f'online-ui-{index}.log').write_text(output)
    assert child.returncode==0 and 'ONLINE UI PASS' in output and 'SCRIPT ERROR' not in output,output
    print(output.strip())
  else:
   child=subprocess.run([godot,'--headless','--script',script],cwd=root,capture_output=True,text=True,timeout=30)
   output=child.stdout+child.stderr;(logs/'network-test.log').write_text(output)
   assert child.returncode==0 and 'NETWORK PASS' in output and 'SCRIPT ERROR' not in output,output
   print(output.strip())
 finally:
  for child in children:
   if child.poll() is None:child.terminate();child.wait(timeout=5)
  server.terminate();server.wait(timeout=5);log.close()
run_case('tests/network_check.gd')
run_case('tests/online_ui_check.gd',True)
print('NETWORK PROCESS CHECKS PASS; all test servers stopped')
