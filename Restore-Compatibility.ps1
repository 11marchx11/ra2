param([Parameter(Mandatory=$true)][string]$BackupDirectory)
$ErrorActionPreference = 'Stop'
$backup = (Resolve-Path -LiteralPath $BackupDirectory).Path
$manifest = Get-Content -LiteralPath (Join-Path $backup 'manifest.json') -Raw | ConvertFrom-Json
$gameDir = $manifest.GameDirectory
$targets = @((Join-Path $gameDir 'game.exe'), (Join-Path $gameDir 'Ra2.exe'))
if (Get-Process -Name game,ra2 -ErrorAction SilentlyContinue | Where-Object { $_.Path -in $targets }) {
    throw 'Save your game and exit Red Alert 2 before restoring.'
}
foreach ($file in @('ddraw.dll','ddraw.ini','RA2.INI')) {
    if ($file -in $manifest.ExistingFiles) {
        Copy-Item -LiteralPath (Join-Path $backup $file) -Destination (Join-Path $gameDir $file) -Force
    } else {
        Remove-Item -LiteralPath (Join-Path $gameDir $file) -ErrorAction SilentlyContinue
    }
}
$key = 'HKCU:\Software\Microsoft\Windows NT\CurrentVersion\AppCompatFlags\Layers'
if (!(Test-Path -LiteralPath $key)) { New-Item -Path $key | Out-Null }
foreach ($property in $manifest.Compatibility.PSObject.Properties) {
    if ($null -eq $property.Value) {
        Remove-ItemProperty -LiteralPath $key -Name $property.Name -ErrorAction SilentlyContinue
    } else {
        New-ItemProperty -LiteralPath $key -Name $property.Name -Value $property.Value -PropertyType String -Force | Out-Null
    }
}
Write-Host "Original files and compatibility settings restored: $gameDir"
