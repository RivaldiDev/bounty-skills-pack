<#
.SYNOPSIS
  Creates a new <project>-bounty folder from the house layout.

.EXAMPLE
  .\new-hunt.ps1 -Project acme
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$Project,
    [string]$Root = (Get-Location).Path
)

$ErrorActionPreference = 'Stop'

$folder = Join-Path $Root ("{0}-bounty" -f $Project.ToLower())
if (Test-Path $folder) {
    throw "folder already exists: $folder"
}

$dirs = @('recon','analysis','findings','notes','repos','poc','poc/evidence','report','recon/raw')
foreach ($d in $dirs) {
    New-Item -ItemType Directory -Force -Path (Join-Path $folder $d) | Out-Null
}

$readme = @"
# $Project - Hunt Folder

**Program:** <program URL>
**Mode:** Batch 01 unauthenticated, passive first.
**Created:** $(Get-Date -Format 'yyyy-MM-dd HH:mm')

## Reward table

| Severity | Reward |
|---|---|
| Critical | |
| High | |
| Medium | |
| Low | |

## Scope

See SCOPE.md.

## Layout

    README.md        this file
    SCOPE.md         scope contract and rules of engagement
    recon/           one output file per batch: batch-NN.md
    analysis/        per candidate deep dives
    findings/        candidates Medium and above
    notes/           running hunt log
    repos/           local clones
    poc/             one directory per finding, plus poc/evidence/
    report/          PDF report, submission draft, MD attachment

## Process

1. Batch 01: six agents, one angle each, passive first.
2. Batch N plus 1 is authored only after every agent of batch N returns.
3. No overlapping batches.
4. Triage gate with seven questions before any report.
5. Deliverables in report/ obey ASD-STE100 Simplified Technical English.
"@
Set-Content -Path (Join-Path $folder 'README.md') -Value $readme -Encoding utf8

$scope = @"
# SCOPE - $Project

Source: <program page URL>

## In scope

| Asset | Class |
|---|---|
| | |

## Out of scope

-

## Allowed methods

- Passive recon.
- Light active probing at human rate on the listed hosts only.

## Not allowed

- Denial of service.
- Social engineering.
- Access to other users' data.

## Severity model

| Severity | Meaning |
|---|---|
| Critical | |
| High | |
| Medium | |
| Low | |
| Info | |
"@
Set-Content -Path (Join-Path $folder 'SCOPE.md') -Value $scope -Encoding utf8

$log = @"
# Hunt log - $Project

All times are local.

## $(Get-Date -Format 'yyyy-MM-dd')

- $(Get-Date -Format 'HH:mm') Intake. Folder created.
"@
Set-Content -Path (Join-Path $folder 'notes\hunt-log.md') -Value $log -Encoding utf8

$gitignore = @"
repos/
poc/*/lib/
poc/*/out/
poc/*/cache/
*.env
"@
Set-Content -Path (Join-Path $folder '.gitignore') -Value $gitignore -Encoding utf8

Write-Host "created $folder" -ForegroundColor Green
