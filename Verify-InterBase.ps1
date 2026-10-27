param(
    [string]$StudioRoot = 'C:\Program Files (x86)\Embarcadero\Studio\37.0'
)
$ErrorActionPreference = 'Stop'
Push-Location -LiteralPath $PSScriptRoot
try {
    $testOutput = Join-Path $PSScriptRoot '.verification'
    New-Item -ItemType Directory -Path $testOutput -Force | Out-Null
    & (Join-Path $PSScriptRoot 'Deploy-InterBase.ps1') -Destination $testOutput
    $compiler = Join-Path $StudioRoot 'bin\dcc32.exe'
    $unitLibrary = Join-Path $StudioRoot 'lib\win32\release'
    & $compiler '-B' '-Q' "-U$unitLibrary" "-E$testOutput" "-N0$testOutput" 'InterBaseSampleCheck.dpr'
    if ($LASTEXITCODE -ne 0) { throw 'InterBase sample test compilation failed.' }
    $testDirectory = Join-Path $testOutput ([Guid]::NewGuid().ToString('N'))
    $testDatabase = Join-Path $testDirectory 'sample.ib'
    $testProgram = Join-Path $testOutput 'InterBaseSampleCheck.exe'
    & $testProgram $testDatabase
    if ($LASTEXITCODE -ne 0) { throw 'InterBase sample runtime test failed.' }
    & $testProgram $testDatabase '--reopen'
    if ($LASTEXITCODE -ne 0) { throw 'InterBase sample process restart test failed.' }
    Write-Output "Test database retained at $testDatabase"
}
finally {
    Pop-Location
}

