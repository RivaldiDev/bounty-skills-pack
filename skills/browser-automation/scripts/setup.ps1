#requires -Version 5

<#
.SYNOPSIS
Bootstrap for the default search and browser stack.
Verifies Node.js. Probes camofox-browser health on port 9377.
Starts the server detached with -StartServer.

.DESCRIPTION
Default stack per operator order:
- Web search: Jina Reader API (s.jina.ai). No local install needed.
- Browser: camofox-browser REST server at http://localhost:9377.
First start downloads the Camoufox binary, about 300 MB. Wait for health.

.EXAMPLE
.\setup.ps1 -StartServer
#>

[CmdletBinding()]
param(
    [switch]$StartServer,
    [int]$Port = 9377,
    [int]$HealthTimeoutSec = 900
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Write-Step {
    param([string]$Message)
    Write-Host "[$((Get-Date).ToString('HH:mm:ss'))] $Message" -ForegroundColor Cyan
}

function Test-CamofoxHealth {
    param([int]$P)
    try {
        $null = Invoke-RestMethod -Uri "http://localhost:$P/health" -TimeoutSec 3
        return $true
    }
    catch { return $false }
}

# Step 1: Node.js check
Write-Step "Checking Node.js..."
$node = Get-Command node -ErrorAction SilentlyContinue
if (-not $node) {
    throw "Node.js not found. Install manually: https://nodejs.org/ or run: winget install OpenJS.NodeJS.22"
}
$nodeVersion = & node -v
Write-Step "Node.js: $nodeVersion"

$npx = Get-Command npx -ErrorAction SilentlyContinue
if (-not $npx) { throw "npx not found. Reinstall Node.js." }

# Step 2: Health probe. Exit early if server already runs.
if (Test-CamofoxHealth -P $Port) {
    Write-Step "camofox already healthy at http://localhost:$Port"
    "status=already-running"
    "health_url=http://localhost:$Port/health"
    exit 0
}
Write-Step "No healthy server on port $Port."

# Step 3: Optional detached start
if (-not $StartServer) {
    Write-Step "Use -StartServer to launch. Or run: npx -y @askjo/camofox-browser"
    "status=ready-not-started"
    exit 0
}

Write-Step "Starting camofox-browser detached (first run downloads ~300 MB binary)..."
$logFile = Join-Path $env:TEMP 'camofox-server.log'
# Start-Process needs a real executable. npx resolves to npx.ps1 here, so use the npx.cmd shim beside node.exe.
$npxDir = Split-Path -Parent $node.Source
$npxCmd = Join-Path $npxDir 'npx.cmd'
if (-not (Test-Path -LiteralPath $npxCmd)) { throw "npx.cmd not found at $npxCmd" }
$proc = Start-Process -WindowStyle Hidden -FilePath $npxCmd `
    -ArgumentList '-y','@askjo/camofox-browser' `
    -RedirectStandardOutput $logFile -RedirectStandardError "$logFile.err" -PassThru
Write-Step "Started pid $($proc.Id). Log: $logFile"

# Step 4: Health wait loop. Generous timeout covers first-run binary download.
Write-Step "Waiting up to $HealthTimeoutSec seconds for health..."
$deadline = (Get-Date).AddSeconds($HealthTimeoutSec)
while ((Get-Date) -lt $deadline) {
    if ($proc.HasExited) {
        Get-Content "$logFile.err" -Tail 20 -ErrorAction SilentlyContinue | Write-Host
        throw "camofox process exited with code $($proc.ExitCode). See log: $logFile.err"
    }
    if (Test-CamofoxHealth -P $Port) {
        Write-Step "camofox healthy at http://localhost:$Port"
        "status=ready"
        "pid=$($proc.Id)"
        "health_url=http://localhost:$Port/health"
        "docs_url=http://localhost:$Port/docs"
        exit 0
    }
    Start-Sleep -Seconds 5
}
throw "Health timeout after $HealthTimeoutSec seconds. Check logs: $logFile"
