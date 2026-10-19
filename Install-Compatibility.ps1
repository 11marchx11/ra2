param(
    [string]$GameDirectory = $PSScriptRoot,
    [string]$ArchivePath
)
$ErrorActionPreference = 'Stop'
$gameDir = (Resolve-Path -LiteralPath $GameDirectory).Path
foreach ($exe in @('Ra2.exe', 'game.exe')) {
    if (!(Test-Path -LiteralPath (Join-Path $gameDir $exe))) { throw "Missing game file: $exe. Install your own game first." }
}
$targets = @((Join-Path $gameDir 'game.exe'), (Join-Path $gameDir 'Ra2.exe'))
if (Get-Process -Name game,ra2 -ErrorAction SilentlyContinue | Where-Object { $_.Path -in $targets }) {
    throw 'Save your game and exit Red Alert 2 before installing.'
}
$archiveHash = '0B13AB89A64C9918189B1DADD449EF6ED3CB3B7B19CABD96D8ADBD95505BB908'
$download = 'https://github.com/FunkyFr3sh/cnc-ddraw/releases/download/v7.1.0.0/cnc-ddraw.zip'
$tempDir = Join-Path ([IO.Path]::GetTempPath()) ('ra2-compat-' + [guid]::NewGuid().ToString('N'))
New-Item -ItemType Directory -Path $tempDir | Out-Null
try {
    if (!$ArchivePath) {
        $ArchivePath = Join-Path $tempDir 'cnc-ddraw.zip'
        Invoke-WebRequest -Uri $download -OutFile $ArchivePath -UseBasicParsing
    }
    if ((Get-FileHash -LiteralPath $ArchivePath -Algorithm SHA256).Hash -ne $archiveHash) {
        throw 'cnc-ddraw archive checksum mismatch. No game files have been changed.'
    }
    $extracted = Join-Path $tempDir 'extracted'
    Expand-Archive -LiteralPath $ArchivePath -DestinationPath $extracted
    if (!(Test-Path -LiteralPath (Join-Path $extracted 'ddraw.dll'))) { throw 'Archive does not contain ddraw.dll.' }
    $backup = Join-Path $gameDir ('repair-backup\compat-' + [guid]::NewGuid().ToString('N'))
    New-Item -ItemType Directory -Path $backup -Force | Out-Null
    $files = @('ddraw.dll', 'ddraw.ini', 'RA2.INI')
    $existingFiles = @($files | Where-Object { Test-Path -LiteralPath (Join-Path $gameDir $_) })
    foreach ($file in $existingFiles) { Copy-Item -LiteralPath (Join-Path $gameDir $file) -Destination $backup }
    $key = 'HKCU:\Software\Microsoft\Windows NT\CurrentVersion\AppCompatFlags\Layers'
    $old = Get-ItemProperty -LiteralPath $key -ErrorAction SilentlyContinue
    $compatibility = [ordered]@{}
    foreach ($target in $targets) {
        $value = if ($old) { $old.PSObject.Properties[$target] } else { $null }
        $compatibility[$target] = if ($value) { $value.Value } else { $null }
    }
    [ordered]@{ GameDirectory=$gameDir; ExistingFiles=$existingFiles; Compatibility=$compatibility } |
        ConvertTo-Json -Depth 4 | Set-Content -LiteralPath (Join-Path $backup 'manifest.json') -Encoding UTF8
    Copy-Item -LiteralPath (Join-Path $extracted 'ddraw.dll') -Destination $gameDir -Force
    Copy-Item -LiteralPath (Join-Path $PSScriptRoot 'config\ddraw.ini') -Destination $gameDir -Force
    $gameIni = Join-Path $gameDir 'RA2.INI'
    if (!(Test-Path -LiteralPath $gameIni)) {
        Copy-Item -LiteralPath (Join-Path $PSScriptRoot 'config\RA2.INI') -Destination $gameIni
    } else {
        Add-Type -TypeDefinition @'
using System;
using System.Runtime.InteropServices;
public static class RA2IniWriter {
    [DllImport("kernel32.dll", CharSet=CharSet.Unicode, SetLastError=true)]
    public static extern bool WritePrivateProfileString(string section, string key, string value, string path);
}
'@
        foreach ($entry in @(@('Intro','Play','no'), @('Video','ScreenWidth','800'), @('Video','ScreenHeight','600'), @('Video','StretchMovies','no'))) {
            if (![RA2IniWriter]::WritePrivateProfileString($entry[0],$entry[1],$entry[2],$gameIni)) { throw 'Could not update RA2.INI.' }
        }
    }
    if (!(Test-Path -LiteralPath $key)) { New-Item -Path $key | Out-Null }
    foreach ($target in $targets) { Remove-ItemProperty -LiteralPath $key -Name $target -ErrorAction SilentlyContinue }
    New-ItemProperty -LiteralPath $key -Name $targets[0] -Value '~ HIGHDPIAWARE' -PropertyType String -Force | Out-Null
    Write-Host "Compatibility fix installed. Launch: $(Join-Path $gameDir 'Ra2.exe')"
    Write-Host "Backup: $backup"
} finally {
    # Only delete the exact temporary directory created by this invocation.
    if ((Split-Path $tempDir -Leaf) -match '^ra2-compat-[0-9a-f]{32}$' -and
        [IO.Path]::GetDirectoryName($tempDir).TrimEnd('\') -eq [IO.Path]::GetTempPath().TrimEnd('\')) {
        Remove-Item -LiteralPath $tempDir -Recurse -Force
    }
}
