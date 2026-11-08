# INSTALL

## Option A: DeepSeek Harness

Skills live in `~/.agents/skills`. Each skill is a folder with a `SKILL.md`.

PowerShell:

    $pack = "C:\path\to\bounty-skills-pack"
    $dest = Join-Path $env:USERPROFILE ".agents\skills"
    New-Item -ItemType Directory -Force -Path $dest | Out-Null
    Get-ChildItem (Join-Path $pack "skills") -Directory | ForEach-Object {
        Copy-Item -Recurse -Force $_.FullName $dest
    }

The doctrine file goes to `~/.dsh/AGENTS.md`:

    Copy-Item (Join-Path $pack "docs\AGENTS.md") (Join-Path $env:USERPROFILE ".dsh\AGENTS.md")

## Option B: Claude Code

Skills live in `~/.claude/skills`.

    $dest = Join-Path $env:USERPROFILE ".claude\skills"
    Get-ChildItem (Join-Path $pack "skills") -Directory | ForEach-Object {
        Copy-Item -Recurse -Force $_.FullName $dest
    }

## Option C: Any other harness

A skill is just a folder with a `SKILL.md`. Read the front matter:

    ---
    name: web3-audit
    description: Smart contract security audit. Use for Solidity or Rust.
    ---

Load the body when the task matches the description. If the body links to
`references/` or `scripts/`, keep those folders next to it.

## Verify

Run `scripts/verify-pack.ps1`. It checks that every skill folder has a SKILL.md and
prints a count.

## Optional tools

The skills assume these are on PATH. Install what you need.

| Tool | Why |
|---|---|
| tinyfish | Web search and page reads |
| cast, forge, anvil | Chain reads and fork PoC |
| slither | Static analysis |
| node, python | Scripts in the skills |
| camofox-browser | Browser PoC screenshots |
| subfinder, httpx, nuclei | Recon (optional, see web2-recon) |

## Paths in the skills

Some skills mention absolute paths from the build host, for example
`~/.agents/skills/browser-automation`. Replace them with your own skill root after install.
