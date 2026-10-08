param(
    [string]$ReleaseNotes = 'Latest improvements and fixes for your Farm Estates workspace.'
)
$ErrorActionPreference = 'Stop'
$projectRoot = Split-Path $PSScriptRoot -Parent
$ApkPath = Join-Path $projectRoot 'web/downloads/farm-estates.apk'
$apkFile = Get-Item -LiteralPath $ApkPath
$versionLine = Get-Content -LiteralPath (Join-Path $projectRoot 'pubspec.yaml') | Where-Object { $_ -match '^version:' } | Select-Object -First 1
if ($versionLine -notmatch '^version:\s*([^+\s]+)\+(\d+)\s*$') { throw 'Expected version name and build number in pubspec.yaml.' }
$versionName = $Matches[1]
$buildNumber = [int]$Matches[2]
$sdkRoot = $env:ANDROID_HOME
if (!$sdkRoot) { $sdkRoot = Join-Path $env:LOCALAPPDATA 'Android/Sdk' }
$aaptTool = Get-ChildItem -LiteralPath (Join-Path $sdkRoot 'build-tools') -Directory |
    Sort-Object Name -Descending | ForEach-Object { Join-Path $_.FullName 'aapt.exe' } |
    Where-Object { Test-Path -LiteralPath $_ } | Select-Object -First 1
if (!$aaptTool) { throw 'Android build tools are required to verify release metadata.' }
$badging = & $aaptTool dump badging $apkFile.FullName
if ($LASTEXITCODE -ne 0) { throw 'Unable to verify APK metadata.' }
$packageLine = $badging | Where-Object { $_ -match '^package:' } | Select-Object -First 1
if ($packageLine -notmatch "name='([^']+)' versionCode='(\d+)' versionName='([^']+)'") { throw 'Invalid APK package metadata.' }
$packageName = $Matches[1]
if ([int]$Matches[2] -ne $buildNumber -or $Matches[3] -ne $versionName) { throw 'APK version differs from pubspec.yaml; rebuild the APK.' }
$manifest = [ordered]@{
    version = $versionName
    buildNumber = $buildNumber
    packageName = $packageName
    apkUrl = 'farm-estates.apk'
    sha256 = (Get-FileHash -LiteralPath $apkFile.FullName -Algorithm SHA256).Hash.ToLowerInvariant()
    sizeBytes = $apkFile.Length
    publishedAt = [DateTime]::UtcNow.ToString('o')
    releaseNotes = $ReleaseNotes
}
$manifestPath = Join-Path $projectRoot 'web/downloads/android-release.json'
[IO.File]::WriteAllText($manifestPath, ($manifest | ConvertTo-Json) + [Environment]::NewLine, [Text.UTF8Encoding]::new($false))
Write-Output "Android release feed prepared: $versionName build $buildNumber."
