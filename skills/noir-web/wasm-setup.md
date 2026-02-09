# WASM Setup

Barretenberg (the proving backend) uses WebAssembly with `SharedArrayBuffer` for multi-threaded proving. `SharedArrayBuffer` requires Cross-Origin-Isolation, which is enabled by setting specific HTTP headers.

## Required HTTP Headers

Both headers must be present on every page that runs the prover:

```
Cross-Origin-Opener-Policy: same-origin
Cross-Origin-Embedder-Policy: require-corp
```

Without these headers, the browser will not expose `SharedArrayBuffer`, and WASM initialization will fail with:

```
ReferenceError: SharedArrayBuffer is not defined
```

## Vite Configuration

```typescript
// vite.config.ts
import { defineConfig } from "vite";
import { nodePolyfills } from "vite-plugin-node-polyfills";

export default defineConfig({
  plugins: [nodePolyfills()],
  server: {
    headers: {
      "Cross-Origin-Opener-Policy": "same-origin",
      "Cross-Origin-Embedder-Policy": "require-corp",
    },
  },
  preview: {
    headers: {
      "Cross-Origin-Opener-Policy": "same-origin",
      "Cross-Origin-Embedder-Policy": "require-corp",
    },
  },
  optimizeDeps: {
    exclude: [
      "@noir-lang/noirc_abi",
      "@noir-lang/acvm_js",
      "@noir-lang/noir_js",
      "@aztec/bb.js",
    ],
  },
  resolve: {
    alias: {
      pino: "pino/browser.js",
    },
  },
});
```

Install the required Vite plugin:

```bash
npm install -D vite-plugin-node-polyfills
```

The `optimizeDeps.exclude` prevents Vite from trying to pre-bundle the WASM-heavy packages, which would fail. The `nodePolyfills` plugin provides Node.js built-in polyfills needed by `bb.js`.

## Webpack Configuration

```javascript
// webpack.config.js
module.exports = {
  // ... other config
  devServer: {
    headers: {
      "Cross-Origin-Opener-Policy": "same-origin",
      "Cross-Origin-Embedder-Policy": "require-corp",
    },
  },
  experiments: {
    asyncWebAssembly: true,
  },
};
```

For Create React App (which uses Webpack internally), you need to eject or use `craco`/`react-app-rewired` to modify the dev server headers. Alternatively, use a proxy or custom middleware.

## Next.js Configuration

```javascript
// next.config.js
const nextConfig = {
  async headers() {
    return [
      {
        source: "/(.*)",
        headers: [
          {
            key: "Cross-Origin-Opener-Policy",
            value: "same-origin",
          },
          {
            key: "Cross-Origin-Embedder-Policy",
            value: "require-corp",
          },
        ],
      },
    ];
  },
  webpack: (config) => {
    config.experiments = {
      ...config.experiments,
      asyncWebAssembly: true,
    };
    return config;
  },
};

module.exports = nextConfig;
```

Remember that Noir proving components must be loaded with `ssr: false` in Next.js. See [React Integration](./react-integration.md) for details.

## Production Deployment

### Vercel

Add a `vercel.json` at the project root:

```json
{
  "headers": [
    {
      "source": "/(.*)",
      "headers": [
        { "key": "Cross-Origin-Opener-Policy", "value": "same-origin" },
        { "key": "Cross-Origin-Embedder-Policy", "value": "require-corp" }
      ]
    }
  ]
}
```

### Netlify

Add a `_headers` file in the publish directory:

```
/*
  Cross-Origin-Opener-Policy: same-origin
  Cross-Origin-Embedder-Policy: require-corp
```

### Cloudflare Pages

Add a `_headers` file in the output directory:

```
/*
  Cross-Origin-Opener-Policy: same-origin
  Cross-Origin-Embedder-Policy: require-corp
```

### Nginx

```nginx
server {
    location / {
        add_header Cross-Origin-Opener-Policy "same-origin" always;
        add_header Cross-Origin-Embedder-Policy "require-corp" always;
    }
}
```

## Troubleshooting

### `SharedArrayBuffer is not defined`

The Cross-Origin-Isolation headers are not set. Verify by opening the browser console and checking:

```javascript
console.log(crossOriginIsolated); // should be true
console.log(typeof SharedArrayBuffer); // should be "function"
```

If `crossOriginIsolated` is `false`, the headers are missing or incorrect. Check the Network tab in DevTools to inspect the response headers on the HTML document.

### CORS Errors with Cross-Origin Resources

When `Cross-Origin-Embedder-Policy: require-corp` is set, **all** cross-origin resources (images, scripts, fonts, API calls) must either:

1. Include a `Cross-Origin-Resource-Policy: cross-origin` response header, or
2. Be loaded with the `crossorigin` attribute

```html
<!-- Add crossorigin attribute to cross-origin resources -->
<img src="https://cdn.example.com/image.png" crossorigin="anonymous" />
<script src="https://cdn.example.com/lib.js" crossorigin="anonymous"></script>
```

If you cannot control the headers on third-party resources, use the less restrictive COEP value:

```
Cross-Origin-Embedder-Policy: credentialless
```

This allows cross-origin resources that do not use credentials (cookies, client certs) without requiring `Cross-Origin-Resource-Policy` headers. Browser support is good in Chrome and Firefox.

### WASM Module Failed to Compile

This usually means the WASM file was not served correctly. Check that:

- The server serves `.wasm` files with `Content-Type: application/wasm`
- The WASM file is not being pre-processed by the bundler (use the `optimizeDeps.exclude` in Vite)
- The WASM file path is correct (check the Network tab for 404s)
- The `vite-plugin-node-polyfills` is installed (required for `@aztec/bb.js`)

### Out of Memory

Large circuits can require significant memory. If the browser tab crashes:

- Check `performance.memory` (Chrome) for memory usage
- Consider reducing circuit size
- On mobile devices, memory limits are stricter -- see [UX Patterns](./ux-patterns.md) for mobile considerations
- Try single-threaded mode if available (uses less memory but is slower)
