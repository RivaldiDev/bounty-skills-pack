# camofox-api Reference

Operational cheat sheet for camofox-browser at `http://localhost:9377`.
Endpoint map verified against live `/openapi.json` on 2026-08-26. Package version 1.14.0.

## Server lifecycle

```powershell
# Start detached (recommended)
Start-Process -WindowStyle Hidden npx -ArgumentList '-y','@askjo/camofox-browser'

# Health gate before any tab call
curl http://localhost:9377/health
```

First start downloads the Camoufox binary. Size is about 300 MB. Wait for health.

Docs UI: `http://localhost:9377/docs`. Spec: `/openapi.json`. Metrics: `/metrics`.

| Env var | Effect |
|---|---|
| `CAMOFOX_PORT` | Listen port. Default 9377 |
| `CAMOFOX_API_KEY` | Enables cookie import routes. Without it they return 403 |
| `CAMOFOX_COOKIES_DIR` | Cookie file dir. Default `~/.camofox/cookies` |
| `CAMOFOX_PROFILE_DIR` | Session state dir. Default `~/.camofox/profiles` |
| `CAMOFOX_TRACES_DIR` | Trace storage. Default `~/.camofox/traces`, TTL 24h |
| `PROXY_HOST`, `PROXY_PORT`, `PROXY_USERNAME`, `PROXY_PASSWORD` | Route all traffic through proxy. GeoIP matches locale and timezone |
| `PROXY_STRATEGY=backconnect` | Rotating gateway provider mode. Sticky IP per context |
| `CAMOUFOX_EXECUTABLE` | Use external Camoufox bundle. Skips bundled download |

## Core loop

```bash
# 1. Create tab -> returns tabId
curl -s -X POST http://localhost:9377/tabs \
  -H "Content-Type: application/json" \
  -d '{"userId":"diablo","sessionKey":"task1","url":"https://target.example","trace":false}'

# 2. Snapshot -> element refs e1..eN. Tab routes need the owner userId query param
curl -s "http://localhost:9377/tabs/<tabId>/snapshot?userId=diablo"
# Add &interactive=true for interactive elements only

# 3. Act on refs
curl -s -X POST "http://localhost:9377/tabs/<tabId>/click?userId=diablo" \
  -H "Content-Type: application/json" -d '{"ref":"e12"}'
curl -s -X POST "http://localhost:9377/tabs/<tabId>/type?userId=diablo" \
  -H "Content-Type: application/json" -d '{"ref":"e7","text":"text"}'
curl -s -X POST "http://localhost:9377/tabs/<tabId>/press?userId=diablo" \
  -H "Content-Type: application/json" -d '{"key":"Enter"}'

# 4. Wait for stability after form submit
curl -s -X POST "http://localhost:9377/tabs/<tabId>/wait?userId=diablo" \
  -H "Content-Type: application/json" -d '{"timeMs":2000}'

# 5. Screenshot -> raw PNG bytes. Write straight to evidence file
curl -s "http://localhost:9377/tabs/<tabId>/screenshot?userId=diablo&fullPage=true" \
  -o poc/evidence/step-01.png

# 6. Teardown
curl -s -X DELETE "http://localhost:9377/tabs/<tabId>?userId=diablo"
curl -s -X DELETE http://localhost:9377/sessions/diablo
```

Live facts from smoke tests on v1.14.0, 2026-08-26:

- Snapshot response fields: `url`, `snapshot`, `refsCount`, `truncated`, `totalChars`
- Snapshot body uses accessibility tree format with `[e1]` style refs
- Screenshot endpoint returns raw PNG binary. Verified valid magic bytes on saved file
- A missing owner id returns `{"error":"userId required"}`
- An idle engine restart kills tabs. Response carries code `browser_restarted`. Create a new tab and re-snapshot

## Endpoint index

| Method | Path | Purpose |
|---|---|---|
| GET | `/` and `/health` | Status and health probe |
| POST/GET | `/tabs` | Create or list tabs |
| POST | `/tabs/{id}/navigate` | Go to URL or macro |
| GET | `/tabs/{id}/snapshot` | Accessibility tree with stable refs |
| POST | `/tabs/{id}/wait` | Selector or timeout wait |
| POST | `/tabs/{id}/click` | Click a ref |
| POST | `/tabs/{id}/upload` | Attach file to upload control |
| POST | `/tabs/{id}/type` | Type into a ref |
| POST | `/tabs/{id}/press` | Keyboard key |
| POST | `/tabs/{id}/scroll` | Scroll page |
| POST | `/tabs/{id}/viewport` | Set viewport size |
| POST | `/tabs/{id}/back` `/forward` `/refresh` | History moves |
| GET | `/tabs/{id}/links` | Extract links |
| GET | `/tabs/{id}/images` | Extract images. Optional inline data URLs |
| GET | `/tabs/{id}/downloads` | List captured downloads |
| GET | `/tabs/{id}/stats` | Tab statistics |
| POST | `/tabs/{id}/evaluate` | Run JavaScript in page |
| POST | `/tabs/{id}/extract` | JSON Schema extraction. Map fields with `x-ref` |
| GET | `/tabs/{id}/screenshot` | Base64 PNG |
| DELETE | `/tabs/{id}` | Close tab |
| DELETE | `/tabs/group/{id}` | Close tab group |
| POST | `/sessions/{userId}/cookies` | Import cookies. Needs Bearer CAMOFOX_API_KEY |
| DELETE | `/sessions/{userId}` | Destroy session. Flushes trace |
| GET/DELETE | `/sessions/{userId}/traces[/{file}]` | List, fetch, delete traces |

OpenClaw compatibility aliases also exist: `POST /tabs/open`, `POST /navigate`, `GET /snapshot`, `POST /act`.

## Cookies and sessions

1. Export Netscape format cookies with a browser extension.
2. Place files in `~/.camofox/cookies/`.
3. Start server with `CAMOFOX_API_KEY` set.
4. Import:

```bash
curl -X POST http://localhost:9377/sessions/diablo/cookies \
  -H "Authorization: Bearer $CAMOFOX_API_KEY" \
  -H "Content-Type: application/json" \
  -d @payload.json
```

Limits: max 500 cookies per request, 5 MB file size. Path traversal outside cookies dir is blocked.
Session persistence keeps cookies and localStorage across restarts. IndexedDB needs opt-in config.

## Search macros

Use as the `url` value in navigate or create tab calls:
`@google_search`, `@youtube_search`, `@amazon_search`, `@reddit_subreddit`, and more.

## Tracing

Set `"trace":true` in create tab body. Zip contains screenshots, DOM snapshots, network, console.
Close the session to flush. Flag cannot change on a live session.

## Troubleshooting

| Symptom | Cause | Fix |
|---|---|---|
| npm install fails on `better-sqlite3` gyp | No MSVC build tools | Install VS 2022 Build Tools with VCTools workload. Then retry |
| Server crashes at start, no Camoufox | Binary download skipped | Do not export `PLAYWRIGHT_SKIP_BROWSER_DOWNLOAD=1`. Or set `CAMOUFOX_EXECUTABLE` |
| Cookie route 403 | No API key configured | Restart server with `CAMOFOX_API_KEY` env var |
| Snapshot huge | Large page | Use `?interactive=true` or offset pagination params |
| Stale refs after click | Page changed | Re-snapshot. Never reuse old refs |

## Companion search layer

Web search does not go through camofox. Use Jina Reader API:

```bash
# Search
curl -s "https://s.jina.ai/<url-encoded-query>" \
  -H "Authorization: Bearer jina_8fdad3f9ae5f400a8da08803810a7abeQqJZqUIH7xvKqHH16iT_xZt7pZpF" \
  -H "X-Respond-With: no-content"

# Read one page as markdown
curl -s "https://r.jina.ai/<full-url>" \
  -H "Authorization: Bearer jina_8fdad3f9ae5f400a8da08803810a7abeQqJZqUIH7xvKqHH16iT_xZt7pZpF" \
  -H "X-Return-Format: markdown"
```

Rate limit with key: 500 requests per minute. Both endpoints verified HTTP 200 on 2026-08-26.
