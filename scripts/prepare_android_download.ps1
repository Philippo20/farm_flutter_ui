param([switch]$BuildWeb)
$ErrorActionPreference = 'Stop'
$projectRoot = Split-Path $PSScriptRoot -Parent
Push-Location $projectRoot
try {
    & flutter build apk --release
    if ($LASTEXITCODE -ne 0) { throw 'Android build failed.' }
    $apk = Join-Path $projectRoot 'build/app/outputs/flutter-apk/app-release.apk'
    if (!(Test-Path -LiteralPath $apk)) { throw 'Release APK was not generated.' }
    $downloads = Join-Path $projectRoot 'web/downloads'
    New-Item -ItemType Directory -Force -Path $downloads | Out-Null
    Copy-Item -LiteralPath $apk -Destination (Join-Path $downloads 'farm-estates.apk') -Force
    if ($BuildWeb) {
        & flutter build web --release
        if ($LASTEXITCODE -ne 0) { throw 'Web build failed.' }
    }
    Write-Output 'APK staged at web/downloads/farm-estates.apk. Deploy the web build to make it available online.'
} finally { Pop-Location }
