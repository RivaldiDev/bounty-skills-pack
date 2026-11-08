# TOOL-POLICY

The tool order this pack assumes. Change it if your harness differs, but keep the order.

## Search and page reads

1. Built in web_search is DISABLED in this pack. Do not call it.
2. WEB SEARCH uses TinyFish. This is the default search path.
   tinyfish search query "<query>" --pretty
   Add --location and --language for geo targeted results.
3. PAGE READ uses TinyFish. The default read path.
   tinyfish fetch content get --format markdown "<url>" ["<url2>" ...]
   One call with several URLs is faster than several calls.
4. Escalation ladder. Start light, escalate only when needed.
   search, then fetch, then agent, then browser.
   tinyfish agent run --url <url> "<goal>" drives a real browser.
5. Local browser for PoC evidence. camofox-browser REST server.
   Start it with npx -y @askjo/camofox-browser
   Health gate before the first tab. curl http://localhost:9377/health
6. Jina Reader is removed. It returns 401. Do not use it.

## Contracts

| Tool | Use |
|---|---|
| cast | Read only chain calls and storage |
| forge | Fork tests and PoC |
| anvil | Local chain |
| slither | Static analysis, never the only check |
| Sourcify | Verified source, prefer over a single explorer |
| solc | Rebuild and compare bytecode |

## Source acquisition order

1. Sourcify v2 endpoint. It returns sources, metadata and compilation in one call.
   https://sourcify.dev/server/v2/contract/<chainId>/<address>?fields=sources,metadata,compilation
2. A block explorer API with a key.
3. The project repository, if it is public.

## Proof standard

- EVM: a forge test on a fork that passes with a real assert.
- HTTP: a raw request and response pair that replays verbatim.
- Browser: a screenshot per step in poc/evidence/step-NN.png.
