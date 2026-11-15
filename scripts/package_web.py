"""Build a compact, observable Safari-friendly Godot Web loader."""
from pathlib import Path
import gzip, hashlib, json, re
root = Path(__file__).resolve().parents[1]
dist = root / 'dist'
wasm = dist / 'index.wasm'
data = wasm.read_bytes()
compressed = gzip.compress(data, compresslevel=9, mtime=0)
(dist / 'engine.wasm.gz').write_bytes(compressed)
assert gzip.decompress(compressed) == data
js_path = dist / 'index.js'
js = js_path.read_text()
# Observe real engine bytes, rather than reporting the tiny PCK as 100%.
old = 'preloader.loadPromise(`${loadPath}.wasm`, size, true)'
new = '''(async () => {
    const response = await fetch('engine.wasm.gz?v=REV', {credentials: 'same-origin'});
    if (!response.ok) throw new Error('Engine HTTP ' + response.status);
    const reader = response.body.getReader();
    const parts = [];
    let received = 0;
    while (true) {
        const {done, value} = await reader.read();
        if (done) break;
        parts.push(value); received += value.length;
        window.bgbProgress?.(received, COMPRESSED_SIZE);
    }
    let bytes = new Uint8Array(await new Blob(parts).arrayBuffer());
    if (bytes[0] === 31 && bytes[1] === 139) {
        window.bgbStage?.('গেম প্রস্তুত হচ্ছে · Unpacking engine');
        if (typeof DecompressionStream === 'undefined') throw new Error('Update Safari: gzip decompression is unavailable');
        bytes = new Uint8Array(await new Response(new Blob([bytes]).stream().pipeThrough(new DecompressionStream('gzip'))).arrayBuffer());
    }
    if (bytes.length !== RAW_SIZE || bytes[0] !== 0 || bytes[1] !== 97) throw new Error('Incomplete engine download. Tap Retry.');
    window.bgbStage?.('3D ইঞ্জিন চালু হচ্ছে · Starting 3D engine');
    return new Response(bytes, {headers: {'Content-Type': 'application/wasm'}});
})()'''
rev = hashlib.sha256(data+(dist/'index.pck').read_bytes()).hexdigest()[:12]
new = new.replace('REV',rev).replace('COMPRESSED_SIZE',str(len(compressed))).replace('RAW_SIZE',str(len(data)))
assert old in js
js = js.replace(old,new)
# Ensure failed download/module/FS initialization rejects, instead of silently hanging.
start = js.index('\t\t\t\tfunction doInit(promise) {')
end = js.index('\n\t\t\t\tpreloader.setProgressFunc',start)
js = js[:start]+'''                async function doInit(promise) {
                    const response = await promise;
                    const module = await Godot(me.config.getModuleConfig(loadPath, response));
                    window.bgbStage?.('মানচিত্র প্রস্তুত হচ্ছে · Preparing world');
                    await module['initFS'](me.config.persistentPaths);
                    me.rtenv = module;
                    if (me.config.unloadAfterInit) Engine.unload();
                }
'''+js[end:]
# Streaming compilation can leave only an unhandled rejection on Safari; expose it.
js = js.replace("WebAssembly.instantiateStreaming(Promise.resolve(r), imports).then(done);", "r.arrayBuffer().then(buffer => WebAssembly.instantiate(buffer, imports)).then(done).catch(window.bgbFail);")
js = js.replace('WebAssembly.instantiate(buffer, imports).then(done);','WebAssembly.instantiate(buffer, imports).then(done).catch(window.bgbFail);')
js_path.write_text(js)
html = (dist/'index.html').read_text()
config = json.loads(re.search(r'const GODOT_CONFIG = (\{.*?\});',html).group(1))
config['persistentPaths'] = [] # Web saves use localStorage; avoid Safari IDB initialization stalls.
config['mainPack'] = 'index.pck?v='+rev
config['fileSizes'][config['mainPack']] = (dist/'index.pck').stat().st_size
shell = (root/'scripts/web_shell.html').read_text().replace('__CONFIG__',json.dumps(config)).replace('__REV__',rev).replace('__DOWNLOAD_MB__',str(round((len(compressed)+(dist/'index.pck').stat().st_size)/1000000)))
(dist/'index.html').write_text(shell)
for stale in ['index.wasm','engine-0.bin','engine-1.bin']:
    (dist/stale).unlink(missing_ok=True)
(dist/'engine-integrity.json').write_text(json.dumps({'bytes':len(data),'compressed_bytes':len(compressed),'sha256':hashlib.sha256(data).hexdigest(),'revision':rev},indent=2))
print(f'Web verified: gzip roundtrip SHA-256 {hashlib.sha256(data).hexdigest()}; {len(compressed)/1048576:.1f} MiB engine')
