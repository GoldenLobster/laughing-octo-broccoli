import './init.js';
import { Innertube, UniversalCache } from 'youtubei.js';

// --- FETCH SHIM ---

async function customFetch(input, init) {
  let url = typeof input === 'string' ? input : (input.url || input.href || input.toString());
  
  // Merge input (if it's a Request object) with init
  const requestMethod = init?.method || input?.method || 'GET';
  const requestBody = init?.body !== undefined ? init.body : input?.body;
  
  let headers = {};
  const rawHeaders = init?.headers || input?.headers;
  if (rawHeaders) {
    if (rawHeaders instanceof Headers) {
      rawHeaders.forEach((value, key) => {
        headers[key] = value;
      });
    } else if (Array.isArray(rawHeaders)) {
      rawHeaders.forEach(([key, value]) => {
        headers[key] = value;
      });
    } else {
      headers = { ...rawHeaders };
    }
  }

  const optionsJson = JSON.stringify({
    method: requestMethod,
    headers: headers,
    body: requestBody ? (typeof requestBody === 'string' ? requestBody : requestBody.toString()) : undefined,
  });

  const responseJson = await globalThis.__hostFetch(url, optionsJson);
  const responseData = JSON.parse(responseJson);

  const arrayBuf = decodeB64(responseData.bodyBase64);

  return {
    ok: responseData.status >= 200 && responseData.status < 300,
    status: responseData.status,
    statusText: responseData.statusText || '',
    headers: {
      get: (name) => {
        const key = Object.keys(responseData.headers || {}).find(k => k.toLowerCase() === name.toLowerCase());
        return key ? responseData.headers[key] : null;
      }
    },
    url: responseData.url || url,
    text: async () => new TextDecoder().decode(arrayBuf),
    json: async () => JSON.parse(new TextDecoder().decode(arrayBuf)),
    arrayBuffer: async () => arrayBuf
  };
}

// --- INNERTUBE SETUP ---

let innertubeInstance = null;
async function getInnertube() {
  if (!innertubeInstance) {
    innertubeInstance = await Innertube.create({
      fetch: customFetch,
      cache: new UniversalCache(false)
    });
  }
  return innertubeInstance;
}

// --- EXPOSED FUNCTIONS ---

globalThis.ytSearch = async function(query) {
  try {
    const yt = await getInnertube();
    const results = await yt.search(query);
    
    // Extract videos from results. 
    // youtubei.js search returns `.videos` among other things, or `results.results` might contain video items.
    // In newer youtubei.js, `.videos` might not exist directly on the first level if it's a mix.
    // Let's use `results.videos` or `results.items.filter(...)`? 
    // `results.videos` is a common shortcut in youtubei.js
    let videos = results.videos;
    if (!videos && results.items) {
      videos = results.items.filter(item => item.type === 'Video' || item.type === 'CompactVideo');
    }
    
    const mapped = (videos || []).map(v => ({
      videoId: v.id,
      title: v.title?.text || v.title || '',
      artist: v.author?.name || v.author || '',
      thumbnailUrl: v.best_thumbnail?.url || v.thumbnails?.[0]?.url || '',
      durationSeconds: v.duration?.seconds || 0
    }));
    
    return JSON.stringify(mapped);
  } catch (err) {
    return JSON.stringify({ error: err.toString() });
  }
};

globalThis.ytResolveStream = async function(videoId) {
  try {
    const yt = await getInnertube();
    const info = await yt.getBasicInfo(videoId);
    
    const format = info.chooseFormat({ type: 'audio', quality: 'best' });
    if (!format) {
      return JSON.stringify({ error: "No suitable audio format found" });
    }
    
    // Sometimes URLs need to be deciphered if there is a signature cipher
    let url = format.url;
    if (!url && format.signature_cipher) {
       url = format.decipher(yt.session.player);
    }
    
    return JSON.stringify({
      url: url,
      mimeType: format.mime_type,
      bitrate: format.bitrate,
      expiresAt: format.approx_duration_ms ? Date.now() + parseInt(format.approx_duration_ms) : undefined
    });
  } catch (err) {
    return JSON.stringify({ error: err.toString() });
  }
};

globalThis.ytRelated = async function(videoId) {
  try {
    const yt = await getInnertube();
    const fullInfo = await yt.getInfo(videoId);
    
    const related = fullInfo.watch_next_feed || [];
    
    const mapped = related.map(v => ({
      videoId: v.id,
      title: v.title?.text || v.title || '',
      artist: v.author?.name || v.author || '',
      thumbnailUrl: v.best_thumbnail?.url || v.thumbnails?.[0]?.url || '',
      durationSeconds: v.duration?.seconds || 0
    }));

    return JSON.stringify(mapped);
  } catch (err) {
    return JSON.stringify({ error: err.toString() });
  }
};
