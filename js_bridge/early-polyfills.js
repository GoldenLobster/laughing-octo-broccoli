import * as encoding from 'text-encoding';
import { encode as btoa, decode as atob } from 'base-64';

if (typeof globalThis.TextEncoder === 'undefined') {
  globalThis.TextEncoder = encoding.TextEncoder;
  globalThis.TextDecoder = encoding.TextDecoder;
}

if (typeof globalThis.btoa === 'undefined') {
  globalThis.btoa = btoa;
  globalThis.atob = atob;
}

if (typeof globalThis.Request === 'undefined') {
  globalThis.Request = class Request {
    constructor(input, init) {
      this.url = typeof input === 'string' ? input : (input.url || input.href || input.toString());
      this.method = init?.method || 'GET';
      this.headers = init?.headers || {};
      this.body = init?.body || null;
      this.redirect = init?.redirect || 'follow';
    }
  };
  globalThis.Response = class Response {};
}

