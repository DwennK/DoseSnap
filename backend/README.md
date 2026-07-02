# DoseSnap Backend

Cloudflare Worker backend for DoseSnap food image analysis.

The iOS app sends a compressed image as base64 to `POST /analyze-food`. The Worker calls the configured MiniMax vision model, validates the response, adds product safety warnings, and returns the stable JSON contract expected by the app.

## Local setup

```bash
cd backend
npm install
npm run check
```

## Local development

Without a MiniMax key, use the explicit mock backend:

```bash
cd backend
npm run dev:mock
```

Then point the iOS app settings to:

```text
http://127.0.0.1:8787/analyze-food
```

This tests the app-to-Worker JSON flow, but it does not run real vision analysis.

For real local MiniMax calls:

```bash
wrangler secret put MINIMAX_API_KEY
wrangler secret put APP_API_TOKEN
npm run dev
```

`APP_API_TOKEN` is required whenever `USE_MOCK_VISION` is not enabled. Do not deploy a real MiniMax-backed Worker without an authorization layer. A static mobile token is not a complete production control; add server-verified App Attest, user auth, or another backend-issued token strategy before public use.

`REQUIRE_DEVICE_INTEGRITY=true` intentionally fails closed until real server-side Apple App Attest / DeviceCheck verification is implemented. Client-sent integrity headers are logged as signals only; they are not treated as proof.

## Deploy

```bash
wrangler secret put MINIMAX_API_KEY
wrangler secret put APP_API_TOKEN
npm run deploy
```

Set the iOS backend endpoint to:

```text
https://<your-worker-domain>/analyze-food
```

## Security posture

- No AI provider key is embedded in the iOS app.
- Images are not stored by default.
- The Worker validates request size and response shape.
- The Worker never returns insulin dose guidance.
- The iOS app remains responsible for local bolus calculation and user confirmation.
