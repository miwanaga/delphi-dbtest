param(
    [string]$Destination = $PSScriptRoot,
    [ValidateSet('Win32', 'Win64')]
    [string]$Platform = 'Win32',
    [string]$RedistRoot = 'C:\Users\Public\Documents\Embarcadero\InterBase\redist\InterBase15'
)
$ErrorActionPreference = 'Stop'
$runtimeFolder = if ($Platform -eq 'Win64') { 'win64_togo' } else { 'win32_togo' }
$runtimeSource = Join-Path $RedistRoot $runtimeFolder
$destinationPath = [System.IO.Path]::GetFullPath($Destination)
if (-not (Test-Path -LiteralPath $runtimeSource -PathType Container)) {
    throw "InterBase redistributables not found: $runtimeSource"
}
New-Item -ItemType Directory -Path $destinationPath -Force | Out-Null
Get-ChildItem -LiteralPath $runtimeSource -Filter '*.dll' -File | ForEach-Object {
    Copy-Item -LiteralPath $_.FullName -Destination $destinationPath -Force
}
$engineDestination = Join-Path $destinationPath 'interbase'
New-Item -ItemType Directory -Path $engineDestination -Force | Out-Null
# Keep existing security/configuration files when deploying again.
foreach ($fileName in @('ADMIN.IB', 'ibconfig', 'interbase.msg', 'license.txt', 'oss_license_notice.txt')) {
    $targetFile = Join-Path $engineDestination $fileName
    if (-not (Test-Path -LiteralPath $targetFile)) {
        Copy-Item -LiteralPath (Join-Path $runtimeSource "InterBase\$fileName") -Destination $targetFile
    }
}
foreach ($folderName in @('intl', 'UDF')) {
    $targetFolder = Join-Path $engineDestination $folderName
    New-Item -ItemType Directory -Path $targetFolder -Force | Out-Null
    Get-ChildItem -LiteralPath (Join-Path $runtimeSource "InterBase\$folderName") -File | ForEach-Object {
        Copy-Item -LiteralPath $_.FullName -Destination $targetFolder -Force
    }
}
$licenseFolder = Join-Path $engineDestination 'license'
New-Item -ItemType Directory -Path $licenseFolder -Force | Out-Null
# Deploy only the Lite license; do not silently switch to a ToGo trial license.
Copy-Item -LiteralPath (Join-Path $runtimeSource 'InterBase\license\IBLite15.slip') -Destination $licenseFolder -Force
Write-Output "InterBase Lite runtime deployed for $Platform to $destinationPath"

