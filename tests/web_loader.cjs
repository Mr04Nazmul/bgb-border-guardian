const fs=require('fs');
const vm=require('vm');
const assert=require('node:assert/strict');
const {webcrypto}=require('node:crypto');
const path=require('path');
const dist=path.resolve(__dirname,'../dist');
const source=fs.readFileSync(path.join(dist,'index.js'),'utf8');
const gzip=fs.readFileSync(path.join(dist,'engine.wasm.gz'));
function sandbox(fetchImpl){
 const ctx=vm.createContext({console,fetch:fetchImpl,Response,Blob,DecompressionStream,Uint8Array,ArrayBuffer,TextDecoder,TextEncoder,crypto:webcrypto,requestAnimationFrame:()=>{},window:{bgbFail:()=>{}},setTimeout,clearTimeout,URL});
 vm.runInContext(source,ctx);
 return ctx;
}
async function run(){
 let received=0;
 const success=sandbox(async()=>new Response(gzip));
 success.window.bgbProgress=(n)=>received=n;
 vm.runInContext("Godot = async () => ({initFS: async (paths) => { if(paths.length) throw Error('Unexpected IndexedDB dependency'); }})",success);
 const engine=vm.runInContext('new Engine({persistentPaths:[]})',success);
 await engine.init('index');
 assert.equal(received,gzip.length);
 assert.ok(engine.rtenv);
 const badFetch=sandbox(async()=>new Response('unavailable',{status:503}));
 const network=vm.runInContext('new Engine({persistentPaths:[]})',badFetch);
 await assert.rejects(network.init('index'),/Engine HTTP 503/);
 const badModule=sandbox(async()=>new Response(gzip));
 vm.runInContext("Godot = async () => { throw Error('Mock wasm init failure'); }",badModule);
 const module=vm.runInContext('new Engine({persistentPaths:[]})',badModule);
 await assert.rejects(module.init('index'),/Mock wasm init failure/);
 const meta=JSON.parse(fs.readFileSync(path.join(dist,'engine-integrity.json')));
 const binary=require('node:zlib').gunzipSync(gzip);
 assert.equal(require('node:crypto').createHash('sha256').update(binary).digest('hex'),meta.sha256);
 await WebAssembly.compile(binary);
 console.log('WEB LOADER PASS: real gzip download/progress/decompression, integrity, wasm compilation, HTTP rejection, module rejection, no IndexedDB initialization dependency');
}
Promise.race([run(),new Promise((_,reject)=>setTimeout(()=>reject(Error('Loader regression test timed out')),15000))]).then(()=>process.exit(0)).catch(e=>{console.error(e);process.exit(1)});
