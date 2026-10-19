$ErrorActionPreference = 'Stop'
$gameDir = Split-Path $PSScriptRoot -Parent
$running = Get-Process -Name game -ErrorAction SilentlyContinue | Where-Object { $_.Path -eq (Join-Path $gameDir 'game.exe') }
if ($running) { throw 'Save your game and exit Red Alert 2 before applying display settings.' }
$iniPath = Join-Path $gameDir 'ddraw.ini'
$ini = Get-Content -LiteralPath $iniPath -Raw
$updates = @{width='0';height='0';fullscreen='false';windowed='false';maintas='true';boxing='false';savesettings='0';toggle_borderless='false';nonexclusive='false';renderer='direct3d9'}
foreach ($section in @('ddraw','game')) {
    $pattern = '(?ms)(^\[' + $section + '\]\r?\n)(.*?)(?=^\[|\z)'
    $ini = [regex]::Replace($ini, $pattern, [System.Text.RegularExpressions.MatchEvaluator]{
        param($match)
        $body = $match.Groups[2].Value
        foreach ($key in $updates.Keys) {
            $linePattern = '(?m)^' + $key + '=.*\r?$'
            if ([regex]::IsMatch($body, $linePattern)) {
                $body = [regex]::Replace($body, $linePattern, "$key=$($updates[$key])")
            } else { $body = "$key=$($updates[$key])`r`n" + $body }
        }
        return $match.Groups[1].Value + $body
    })
}
Set-Content -LiteralPath $iniPath -Value $ini -Encoding ascii
$gameIniPath = Join-Path $gameDir 'RA2.INI'
$gameIni = Get-Content -LiteralPath $gameIniPath -Raw
$gameIni = $gameIni -replace '(?m)^ScreenWidth=.*\r?$','ScreenWidth=800' -replace '(?m)^ScreenHeight=.*\r?$','ScreenHeight=600'
Set-Content -LiteralPath $gameIniPath -Value $gameIni -Encoding ascii
Write-Host 'Exclusive fullscreen enabled. Original game/menu resolution: 800 x 600.'
