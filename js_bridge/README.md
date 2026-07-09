# JS Bridge

This is a dev-time-only Node/npm workspace. It is used once to produce a static JS file that gets copied into the app assets.

**Note:** This code never runs at app runtime. It is strictly a build step for the Innertube JS bundling.

## Build Instructions

1. Run `npm install` to install dependencies.
2. Run `npm run build` to generate the self-contained JS bundle.
3. Copy the resulting `dist/bridge.bundle.js` into your Flutter app at `app/assets/js/bridge.bundle.js`.
