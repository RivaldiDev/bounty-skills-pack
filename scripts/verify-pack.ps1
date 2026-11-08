<#
.SYNOPSIS
  Verifies the pack and prints a summary.

.DESCRIPTION
  Checks that every folder under .\skills has a SKILL.md with YAML front matter.
  Prints file counts and total size.
#>
[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'

$packRoot = Split-Path -Parent $PSScriptRoot
$srcRoot  = Join-Path $packRoot 'skills'

$skills   = Get-ChildItem $srcRoot -Directory
$missing  = @()
$okCount  = 0

foreach ($s in $skills) {
    $skillFile = Join-Path $s.FullName 'SKILL.md'
    if (-not (Test-Path $skillFile)) {
        $missing += $s.Name
        continue
    }
    $head = Get-Content $skillFile -TotalCount 1 -ErrorAction SilentlyContinue
    if ($head -ne '---') {
        Write-Host "warn  $($s.Name): SKILL.md has no YAML front matter" -ForegroundColor DarkYellow
    }
    $okCount++
}

Write-Host ""
Write-Host "skills with SKILL.md : $okCount / $($skills.Count)" -ForegroundColor Cyan
if ($missing.Count -gt 0) {
    Write-Host "missing SKILL.md     : $($missing -join ', ')" -ForegroundColor Red
}

$all = Get-ChildItem $packRoot -Recurse -File
$sum = ($all | Measure-Object Length -Sum).Sum

Write-Host "total files          : $($all.Count)"
Write-Host "total size           : $([math]::Round($sum / 1MB, 2)) MB"
Write-Host ""

foreach ($section in @('skills','workflows','hunt-method','docs','tether-hunt','scripts')) {
    $p = Join-Path $packRoot $section
    if (Test-Path $p) {
        $f = Get-ChildItem $p -Recurse -File
        Write-Host ("{0,-14} {1,5} files  {2,8} KB" -f $section, $f.Count, [math]::Round((($f | Measure-Object Length -Sum).Sum)/1KB, 1))
    }
}
