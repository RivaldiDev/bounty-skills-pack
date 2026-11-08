---
name: browser-automation
description: |
  Default entry point for web search and browser automation.
  Web search uses the Jina Reader API at s.jina.ai. Page reading uses r.jina.ai.
  Browser automation uses camofox-browser. This is an anti-detection headless Firefox REST server at localhost:9377.
  Use when a task needs search results, page text, clicks, typing, forms, screenshots, login flows, cookies, or stealth browsing.
  Trigger keywords: browser automation, web search, page read, scrape, crawl, screenshot, stealth, anti-bot, Cloudflare bypass,
  Jina Reader, s.jina.ai, r.jina.ai, camofox, camoufox, headless, login flow, cookie import.
---

# Web Search And Browser Automation

## RULES

1. Do not use the built-in `web_search` tool. The operator disabled it.
2. Do not use Playwright, Puppeteer, agent-browser, or OpenReverse. The previous stack is removed.
3. All web search goes through `s.jina.ai`. All single page reads go through `r.jina.ai`.
4. All page interaction goes through the camofox REST API at `http://localhost:9377`.
5. Take a snapshot before every interaction. Use only refs from the latest snapshot.
6. Save a screenshot for every attack step. Use `poc/evidence/step-NN.png` naming.
7. Close tabs after use. Destroy the session at task end.
8. Every claim needs real command output. Do not fabricate results.

## PART 1: WEB SEARCH AND PAGE READ (JINA READER API)

The API key is set by operator order:

```
jina_8fdad3f9ae5f400a8da08803810a7abeQqJZqUIH7xvKqHH16iT_xZt7pZpF
```

Both endpoints returned HTTP 200 with this key on 2026-08-26. Rate limit is 500 requests per minute with the key.

### Search

```bash
curl -s "https://s.jina.ai/<url-encoded-query>" \
  -H "Authorization: Bearer jina_8fdad3f9ae5f400a8da08803810a7abeQqJZqUIH7xvKqHH16iT_xZt7pZpF" \
  -H "X-Respond-With: no-content"
```

The response is a ranked result list. Each result has Title, URL Source, Description, and Date.

### Read one page

```bash
curl -s "https://r.jina.ai/<full-target-url>" \
  -H "Authorization: Bearer jina_8fdad3f9ae5f400a8da08803810a7abeQqJZqUIH7xvKqHH16iT_xZt7pZpF" \
  -H "X-Return-Format: markdown"
```

The response is clean markdown of the target page. Use this instead of raw HTML fetch for readable content.

### Request headers

| Header | Value | Effect |
|---|---|---|
| Authorization | Bearer key | Required. Raises rate limit to 500 requests per minute |
| X-Respond-With | no-content | Search only. Returns snippets without page content |
| X-With-Generated-Alts | true | Adds an LLM summary answer to search results |
| X-Return-Format | markdown | Reader only. Returns markdown |
| X-Return-Format | screenshot | Reader only. Returns a full page screenshot |
| X-Timeout | seconds | Reader only. Sets browser wait timeout |

### Decision rule

| Need | Endpoint |
|---|---|
| Ranked results for a topic | `s.jina.ai` |
| Text of one known URL | `r.jina.ai` |
| Interaction, JS render, login, cookies, screenshots | camofox-browser |

## PART 2: BROWSER AUTOMATION (CAMOFOX-BROWSER)

### What it is

camofox-browser is a REST server around the Camoufox engine.
Camoufox is a Firefox fork. It spoofs fingerprints at C++ level before any JavaScript runs.
It defeats Google, Cloudflare, and most bot detection.
Snapshots are accessibility trees with stable refs. Refs are about 90 percent smaller than raw HTML.

Repo: https://github.com/jo-inc/camofox-browser

### Start the server

```powershell
npx -y @askjo/camofox-browser
# Server listens on http://localhost:9377
# First start downloads the Camoufox binary, about 300 MB
```

Or run the bootstrap script in `scripts/setup.ps1`.

Verify health before first use:

```bash
curl http://localhost:9377/health
```

Full interactive docs live at `http://localhost:9377/docs`. The machine spec is at `/openapi.json`.

### Core workflow

Step 1. Create a tab. The response gives a `tabId`.

```bash
curl -s -X POST http://localhost:9377/tabs \
  -H "Content-Type: application/json" \
  -d '{"userId":"diablo","sessionKey":"task1","url":"https://target.example"}'
```

Step 2. Snapshot the page. The response gives element refs like `e1`, `e2`, `e3`.

```bash
curl -s "http://localhost:9377/tabs/<tabId>/snapshot?userId=<userId>"
```

Add `&interactive=true` to list only interactive elements.
Tab routes need the owner `userId` query parameter. A missing value returns `{"error":"userId required"}`.

Step 3. Act on refs from the latest snapshot.

```bash
# Click an element
curl -s -X POST http://localhost:9377/tabs/<tabId>/click \
  -H "Content-Type: application/json" -d '{"ref":"e12"}'

# Type text into a field
curl -s -X POST http://localhost:9377/tabs/<tabId>/type \
  -H "Content-Type: application/json" -d '{"ref":"e7","text":"payload"}'

# Press a key
curl -s -X POST http://localhost:9377/tabs/<tabId>/press \
  -H "Content-Type: application/json" -d '{"key":"Enter"}'

# Navigate to another URL or macro
curl -s -X POST http://localhost:9377/tabs/<tabId>/navigate \
  -H "Content-Type: application/json" -d '{"url":"https://target.example/login"}'
```

Step 4. Capture evidence. The endpoint returns raw PNG bytes. Write them straight to file.

```bash
curl -s "http://localhost:9377/tabs/<tabId>/screenshot?userId=<userId>&fullPage=true" -o poc/evidence/step-01.png
```

Verified live on package version 1.14.0. Output was a valid PNG with correct magic bytes.

Note on idle behavior. The engine can restart when tabs sit idle. A dead tab returns code `browser_restarted`.
Recover by creating a new tab and taking a fresh snapshot. Never reuse refs from a restarted engine.

Step 5. Close everything.

```bash
curl -s -X DELETE http://localhost:9377/tabs/<tabId>
curl -s -X DELETE http://localhost:9377/sessions/diablo
```

### Endpoint map

This map comes from the live `/openapi.json` on 2026-08-26.

| Method | Path | Purpose |
|---|---|---|
| POST | `/tabs` | Create a tab. Body has userId, sessionKey, url, optional trace |
| GET | `/tabs` | List open tabs |
| POST | `/tabs/{id}/navigate` | Go to URL or macro |
| GET | `/tabs/{id}/snapshot` | Accessibility snapshot with refs |
| POST | `/tabs/{id}/wait` | Wait for selector or timeout |
| POST | `/tabs/{id}/click` | Click a ref |
| POST | `/tabs/{id}/type` | Type into a ref |
| POST | `/tabs/{id}/press` | Press a key |
| POST | `/tabs/{id}/scroll` | Scroll the page |
| POST | `/tabs/{id}/upload` | Attach a file to an upload control |
| POST | `/tabs/{id}/viewport` | Set viewport size |
| POST | `/tabs/{id}/evaluate` | Run JavaScript in the page |
| POST | `/tabs/{id}/extract` | Structured extraction with JSON Schema and x-ref |
| GET | `/tabs/{id}/links` | Extract page links |
| GET | `/tabs/{id}/images` | Extract page images |
| GET | `/tabs/{id}/downloads` | List captured downloads |
| GET | `/tabs/{id}/stats` | Tab statistics |
| GET | `/tabs/{id}/screenshot` | Raw PNG screenshot bytes |
| DELETE | `/tabs/{id}` | Close a tab |
| DELETE | `/tabs/group/{id}` | Close all tabs in a group |
| POST | `/sessions/{userId}/cookies` | Import cookies. Needs CAMOFOX_API_KEY auth |
| DELETE | `/sessions/{userId}` | Destroy session |
| GET | `/sessions/{userId}/traces` | List trace zips |
| GET/DELETE | `/sessions/{userId}/traces/{file}` | Fetch or delete one trace zip |
| GET | `/health` | Health check. Probe before use |
| GET | `/metrics` | Prometheus metrics |
| POST | `/start`, `/stop` | Start or stop the browser engine |

### Sessions, cookies, and authentication

Session state persists at `~/.camofox/profiles/`. Cookies and localStorage survive restarts.
Log in once. Later tabs restore the authenticated state automatically.

Cookie import skips interactive login:

1. Start the server with `CAMOFOX_API_KEY` set. Without it, cookie routes return 403.
2. Export Netscape format cookies with a browser extension.
3. Put the file in `~/.camofox/cookies/`.
4. POST it to `/sessions/{userId}/cookies` with the Bearer key.
5. New tabs to that domain are now authenticated.

Hard login flows support VNC visual login through noVNC. Export storage state for reuse.

### Proxy routing

Set env vars before server start. GeoIP then matches locale, timezone, and geolocation to the exit IP.

```bash
export PROXY_HOST=166.88.179.132
export PROXY_PORT=46040
export PROXY_USERNAME=myuser
export PROXY_PASSWORD=mypass
```

Backconnect providers need `PROXY_STRATEGY=backconnect`. Each context then gets its own sticky IP.

### Tracing for evidence

Set `"trace":true` in the create tab body. The trace zip holds screenshots, DOM snapshots, network, and console.
Close the session to flush the trace. Then list, fetch, and inspect it.
Tracing cannot change on a live session. Delete the session first if you need the flag.

### Bounty PoC integration

Browser based PoCs must produce step screenshots. Number shots in attack order as `poc/evidence/step-NN.png`.
Embed each shot in the report PDF at the matching step.
A PoC without step screenshots is not done.

### Search macros

Navigation accepts macros such as `@google_search`, `@youtube_search`, `@amazon_search`, and `@reddit_subreddit`.
Send them as the `url` value in navigate or create tab calls.

## BOOTSTRAP

Run `scripts/setup.ps1` for first time setup. It checks Node.js, probes health, and starts the server detached.
Use `-StartServer` to launch. First start downloads the Camoufox binary, about 300 MB. Wait for health.

## ROUTING

| Next need | Route to |
|---|---|
| Analyze a captured request | `anything-analyzer` or `js-reverse` skill |
| JS breakpoints, hooks, CDP debug | `jshookmcp` skill |
| Recover a client signature algorithm | `js-reverse` skill |
| Windows desktop GUI automation | Not covered here. OpenReverse is removed from this stack |

## COMPLETION CHECK

Pass all items before you claim completion:

- [ ] Every claim traces to real command output
- [ ] Snapshot taken before every interaction
- [ ] Screenshots saved for every attack step
- [ ] Tabs closed and sessions destroyed
- [ ] No call to `web_search`, Playwright, agent-browser, or OpenReverse
