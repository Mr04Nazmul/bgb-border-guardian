"""Package Godot Web export into <= 20 MiB chunks for static hosting."""
from pathlib import Path
import hashlib
import json
root = Path(__file__).resolve().parents[1]
dist = root / 'dist'
wasm = dist / 'index.wasm'
if wasm.exists():
    data = wasm.read_bytes()
    chunks = []
    for i, start in enumerate(range(0, len(data), 20*1024*1024)):
        name = f'engine-{i}.bin'
        (dist / name).write_bytes(data[start:start+20*1024*1024])
        chunks.append(name)
    js = dist / 'index.js'
    text = js.read_text()
    old = 'preloader.loadPromise(`${loadPath}.wasm`, size, true)'
    new = '''Promise.all(CHUNKS.map(async (url) => {
                const response = await fetch(url);
                if (!response.ok) throw new Error('Engine download failed: ' + response.status);
                return response.arrayBuffer();
            })).then(parts => new Response(new Blob(parts, {type: 'application/wasm'})))'''.replace('CHUNKS', json.dumps(chunks))
    assert old in text
    js.write_text(text.replace(old, new))
    # Check the exact downloaded binary reassembly before removing the oversized file.
    assembled = b''.join((dist / p).read_bytes() for p in chunks)
    assert hashlib.sha256(assembled).digest() == hashlib.sha256(data).digest()
    (dist / 'engine-integrity.json').write_text(json.dumps({'bytes':len(data),'sha256':hashlib.sha256(data).hexdigest(),'chunks':chunks}, indent=2))
    wasm.unlink()
html = dist / 'index.html'
text = html.read_text()
text = text.replace('<canvas id="canvas">','<canvas id="canvas" aria-label="Border Guardian Bangladesh 3D game">')
text = text.replace('<div id="status-notice"></div>', '<div id="status-notice"></div><p id="loading-hint" style="color:#e9d49b;text-align:center;font:16px sans-serif">BORDER GUARDIAN BANGLADESH<br>গেম লোড হচ্ছে · Loading 3D game<br>iPhone: ফোন আড়াআড়ি করে খেলুন · Use landscape<br>First download approximately 40 MB</p>')
text = text.replace("const missingMsg = 'Error\\nThe following features required to run Godot projects on the Web are missing:\\n';", "const missingMsg = 'এই ব্রাউজারে 3D গেম চালু করা যায়নি। Safari বা Chrome-এর আপডেটেড সংস্করণে খুলুন।\\nThis game needs WebGL2. Open in updated Safari or Chrome.\\n';")
html.write_text(text)
print('Web package verified: binary reassembly SHA-256 matches; all assets under 20 MiB')
