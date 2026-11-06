
param(
  [string]$ProfileDir = "$env:USERPROFILE\.dsh\profiles\web"
)
$ErrorActionPreference = 'Stop'
$repo = Split-Path $PSScriptRoot -Parent
$source = Join-Path $repo '0.8.6\patched'
$target = Join-Path $ProfileDir 'node_modules\dsh-ego-browser'
$stamp = Get-Date -Format 'yyyyMMdd-HHmmss'

if (-not (Test-Path -LiteralPath $source)) { throw "Missing patch source: $source" }
if (-not (Test-Path -LiteralPath $target)) { throw "dsh-ego-browser is not installed at $target" }

$backup = Join-Path $target ('.patch-backups\' + $stamp)
$copied = 0
Get-ChildItem -LiteralPath $source -Recurse -File | ForEach-Object {
  if ($_.Name -like '*.bak') { return }
  $rel = $_.FullName.Substring($source.Length).TrimStart('\')
  $dst = Join-Path $target $rel
  $dir = Split-Path $dst -Parent
  if (-not (Test-Path -LiteralPath $dir)) { New-Item -ItemType Directory -Force -Path $dir | Out-Null }
  if (Test-Path -LiteralPath $dst) {
    $bd = Join-Path $backup $rel
    $bdDir = Split-Path $bd -Parent
    if (-not (Test-Path -LiteralPath $bdDir)) { New-Item -ItemType Directory -Force -Path $bdDir | Out-Null }
    Copy-Item -LiteralPath $dst -Destination $bd -Force
  }
  Copy-Item -LiteralPath $_.FullName -Destination $dst -Force
  $copied++
}

node --check (Join-Path $target 'lib\client.js')
if ($LASTEXITCODE -ne 0) { throw "node --check failed: lib/client.js" }
node --check (Join-Path $target 'lib\index.js')
if ($LASTEXITCODE -ne 0) { throw "node --check failed: lib/index.js" }

$client = Get-Content -LiteralPath (Join-Path $target 'lib\client.js') -Raw -Encoding UTF8
if ($client -notmatch 'EGO_FORCE_FLOATING_PATCH') { throw "floating patch marker missing" }

Write-Host "copied $copied file(s); backup: $backup"
Write-Host "Refresh the DSH page. If the old sidebar is still shown, restart DSH."
