import { readFileSync } from 'fs';
import { runInNewContext } from 'vm';
import { resolve } from 'path';

const realFetch = globalThis.fetch;

const sandbox = {
  console: console,
  setTimeout: setTimeout,
  clearTimeout: clearTimeout,
  __hostFetch: async (url, optionsJson) => {
    console.log('[__hostFetch] =>', url);
    const options = JSON.parse(optionsJson);
    const res = await realFetch(url, options);
    const arrayBuffer = await res.arrayBuffer();
    const base64 = Buffer.from(arrayBuffer).toString('base64');
    
    const headers = {};
    res.headers.forEach((v, k) => headers[k] = v);

    return JSON.stringify({
      status: res.status,
      statusText: res.statusText,
      headers: headers,
      url: res.url,
      bodyBase64: base64
    });
  }
};

const code = readFileSync(resolve('./dist/bridge.bundle.js'), 'utf8');

async function runTest() {
  console.log("Loading bundle into sandbox...");
  runInNewContext(code, sandbox);
  
  console.log("Calling ytSearch...");
  const searchJson = await sandbox.ytSearch("test song");
  console.log("ytSearch result:", searchJson.substring(0, 1000));
}

runTest().catch(console.error);
