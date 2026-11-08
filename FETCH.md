# FETCH — how a harness reads this repo

Three ways to get the content, from heaviest to lightest. Pick the one your harness supports.

## 1. Clone (best)

    git clone https://github.com/RivaldiDev/bounty-skills-pack.git

All 639 files. Every skill is a folder with a `SKILL.md`.

## 2. GitHub API (no git needed)

List the tree, then fetch each file:

    GET https://api.github.com/repos/RivaldiDev/bounty-skills-pack/git/trees/main?recursive=1

That returns every path with its type and size. Then read any file:

    GET https://api.github.com/repos/RivaldiDev/bounty-skills-pack/contents/<path>

The response has `content` as base64. Decode it to get the text.

Rate limit is 60 requests per hour without a token, 5000 with one. A full pull is 639
requests, so use a token or use the clone.

## 3. Raw file fetch (one request per file)

    https://raw.githubusercontent.com/RivaldiDev/bounty-skills-pack/main/<path>

Plain text, no base64, no auth. This is the simplest path and it works with any HTTP
fetcher, including the built-in web fetch tool.

## Enumerate every file

[FILES.json](FILES.json) at the repo root lists every path and its size:

    GET https://raw.githubusercontent.com/RivaldiDev/bounty-skills-pack/main/FILES.json

Fetch that once, then loop the raw URLs.

## Example: fetch only the skills

    BASE=https://raw.githubusercontent.com/RivaldiDev/bounty-skills-pack/main
    curl -s "$BASE/FILES.json" \
      | jq -r '.[] | select(.path | startswith("skills/")) | .path' \
      | while read -r p; do
          mkdir -p "out/$(dirname "$p")"
          curl -s "$BASE/$p" -o "out/$p"
        done

## Example: fetch the method docs only

These are the three files worth reading first, and they are small:

    curl -s https://raw.githubusercontent.com/RivaldiDev/bounty-skills-pack/main/hunt-method/HUNT-LOOP.md
    curl -s https://raw.githubusercontent.com/RivaldiDev/bounty-skills-pack/main/hunt-method/TOOL-POLICY.md
    curl -s https://raw.githubusercontent.com/RivaldiDev/bounty-skills-pack/main/hunt-method/LESSONS-TETHER.md

## Notes

- The repo is public. No token is needed for raw fetches.
- One file is 1.25 MB: `skills/pentest-tools/src-hunter/references/payloader/raw/web.json`.
  Skip it if your fetcher caps response size.
- `skills/reverse-skill-router/` contains a full copy of the skill suite. If you only want
  the skills once, fetch `skills/<name>/` and skip `skills/reverse-skill-router/`.
