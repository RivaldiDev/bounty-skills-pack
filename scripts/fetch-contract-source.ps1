<#
.SYNOPSIS
  Downloads verified contract source from Sourcify.

.EXAMPLE
  .\fetch-contract-source.ps1 -ChainId 1 -Address 0xdAC17F958D2ee523a2206206994597C13D831ec7
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)][int]$ChainId,
    [Parameter(Mandatory = $true)][string]$Address,
    [string]$OutDir = (Join-Path (Get-Location).Path 'repos')
)

$ErrorActionPreference = 'Stop'

$url = "https://sourcify.dev/server/v2/contract/$ChainId/$Address?fields=sources,metadata,compilation"
Write-Host "GET $url" -ForegroundColor DarkGray

$tmp = Join-Path $env:TEMP ("sourcify-$ChainId-$Address.json")
try {
    $code = & curl.exe -sS -o $tmp -w "%{http_code}" --max-time 90 $url
} catch {
    throw "curl failed: $($_.Exception.Message)"
}

if ($code -ne '200') {
    throw "Sourcify returned HTTP $code for $Address on chain $ChainId"
}

$doc = Get-Content $tmp -Raw | ConvertFrom-Json
if (-not $doc.sources) {
    throw "no sources in the Sourcify response"
}

$compiler = $doc.compilation.compilerVersion
$name     = $doc.compilation.name
$match    = $doc.match

Write-Host "contract : $name"
Write-Host "compiler : $compiler"
Write-Host "match    : $match"

$dest = Join-Path $OutDir $Address
New-Item -ItemType Directory -Force -Path $dest | Out-Null

foreach ($p in $doc.sources.PSObject.Properties) {
    $safe = ($p.Name -replace '^project:/?', '') -replace '[\\/]', '__'
    $file = Join-Path $dest $safe
    Set-Content -Path $file -Value $p.Value.content -Encoding utf8
    Write-Host ("  wrote {0} ({1} chars)" -f $safe, $p.Value.content.Length)
}

Write-Host ""
Write-Host "source in $dest" -ForegroundColor Green
Write-Host "next: rebuild with the exact compiler and compare the runtime bytecode."
Write-Host "      strip the CBOR metadata before the compare."
