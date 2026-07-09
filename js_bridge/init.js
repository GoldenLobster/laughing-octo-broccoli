import './early-polyfills.js';
import * as whatwgUrl from 'whatwg-url';
import { EventTarget, Event } from 'event-target-shim';

if (typeof globalThis.URL === 'undefined') {
  globalThis.URL = whatwgUrl.URL;
  globalThis.URLSearchParams = whatwgUrl.URLSearchParams;
}

if (typeof globalThis.EventTarget === 'undefined') {
  globalThis.EventTarget = EventTarget;
  globalThis.Event = Event;
  globalThis.CustomEvent = class CustomEvent extends Event {
    constructor(type, eventInitDict) {
      super(type, eventInitDict);
      this.detail = eventInitDict?.detail ?? null;
    }
  };
}


if (typeof globalThis.Headers === 'undefined') {
  globalThis.Headers = class Headers {
    constructor(init) {
      this.map = new Map();
      if (init instanceof Headers) {
        init.forEach((value, key) => this.append(key, value));
      } else if (Array.isArray(init)) {
        init.forEach(([key, value]) => this.append(key, value));
      } else if (init) {
        Object.entries(init).forEach(([key, value]) => this.append(key, value));
      }
    }
    append(name, value) {
      const key = name.toLowerCase();
      if (this.map.has(key)) {
        this.map.set(key, this.map.get(key) + ', ' + value);
      } else {
        this.map.set(key, value);
      }
    }
    delete(name) { this.map.delete(name.toLowerCase()); }
    get(name) { return this.map.get(name.toLowerCase()) || null; }
    has(name) { return this.map.has(name.toLowerCase()); }
    set(name, value) { this.map.set(name.toLowerCase(), value); }
    forEach(callback, thisArg) {
      for (const [key, value] of this.map.entries()) {
        callback.call(thisArg, value, key, this);
      }
    }
    *keys() { for (const key of this.map.keys()) yield key; }
    *values() { for (const value of this.map.values()) yield value; }
    *entries() { for (const entry of this.map.entries()) yield entry; }
  };
}

globalThis.decodeB64 = function(b64) {
  const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/';
  const lookup = new Uint8Array(256);
  for (let i = 0; i < chars.length; i++) { lookup[chars.charCodeAt(i)] = i; }
  
  let bufferLength = b64.length * 0.75, len = b64.length, i, p = 0, encoded1, encoded2, encoded3, encoded4;
  if (b64[b64.length - 1] === "=") { bufferLength--; if (b64[b64.length - 2] === "=") bufferLength--; }
  
  const bytes = new Uint8Array(bufferLength);
  for (i = 0; i < len; i += 4) {
    encoded1 = lookup[b64.charCodeAt(i)];
    encoded2 = lookup[b64.charCodeAt(i+1)];
    encoded3 = lookup[b64.charCodeAt(i+2)];
    encoded4 = lookup[b64.charCodeAt(i+3)];
    
    bytes[p++] = (encoded1 << 2) | (encoded2 >> 4);
    if (encoded3 !== 64) bytes[p++] = ((encoded2 & 15) << 4) | (encoded3 >> 2);
    if (encoded4 !== 64) bytes[p++] = ((encoded3 & 3) << 6) | (encoded4 & 63);
  }
  return bytes.buffer;
};
