param([string]$Flutter = 'flutter')

# Diagnostic workaround for D3D11 device-hung / EGL context-lost errors.
# Stop the existing Windows app first. Hot reload cannot replace a lost GPU context.
# This changes rendering only for this debug run, not for distributed builds.
$ErrorActionPreference = 'Stop'
$projectRoot = Split-Path $PSScriptRoot -Parent
Push-Location $projectRoot
try {
    & $Flutter run -d windows --no-enable-impeller --enable-software-rendering
    if ($LASTEXITCODE -ne 0) { throw "Windows diagnostic run failed ($LASTEXITCODE)." }
} finally {
    Pop-Location
}
