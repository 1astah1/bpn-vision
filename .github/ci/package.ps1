# Builds the BPN Vision portable packages the way Veyra builds its own releases: the previous public
# package supplies every runtime file (Qt, FFmpeg, vendor DLLs, models, shaders); this build replaces
# the EXE, the QML front end, the catalogue and the documents.
param([string]$Version, [string]$OutDir)
$ErrorActionPreference = "Stop"
Import-Module "$env:GITHUB_WORKSPACE\.github\ci\ci.psm1"
Use-Log "package"
$ws = $env:GITHUB_WORKSPACE
$exe = Get-ChildItem -Path "$ws\out" -Filter veyra_qml_ui.exe -Recurse | Select-Object -First 1
if (-not $exe) { Write-Log "veyra_qml_ui.exe was not built"; exit 1 }
Write-Log "EXE $($exe.FullName) $([math]::Round($exe.Length / 1MB, 1)) MB"
$work = Join-Path $env:RUNNER_TEMP "pkg"
New-Item -ItemType Directory -Force -Path $work, $OutDir | Out-Null

foreach ($gpu in @("AMD", "NVIDIA")) {
    $upstream = "Veyra-2.1.6-$gpu-win64-portable"
    $zip = "$work\$upstream.zip"
    Step "download $upstream" { Get-File "https://github.com/Likely7/Veyra-NRVideo/releases/download/v2.1.6/$upstream.zip" $zip }
    Step "extract $upstream" { tar -xf $zip -C $work }
    Remove-Item -Force $zip
    $name = "BPN-Vision-$Version-$gpu-win64-portable"
    $dir = "$work\$name"
    Rename-Item "$work\$upstream" $name
    Step "replace files ($gpu)" {
        Copy-Item -Force $exe.FullName "$dir\veyra_qml_ui.exe"
        Copy-Item -Recurse -Force "$ws\qml\*" "$dir\qml\"
        Copy-Item -Force "$ws\i18n\catalog.json" "$dir\i18n\catalog.json"
        Copy-Item -Force "$ws\README.md", "$ws\CHANGES_BPN.md", "$ws\LICENSE" $dir
        Set-Content -Path "$dir\BPN-VISION.txt" -Encoding utf8 -Value @(
            "BPN Vision $Version ($gpu) - https://github.com/1astah1/bpn-vision",
            "Based on Veyra 2.1.6 by Likely7 (GPL-3.0): https://github.com/Likely7/Veyra-NRVideo",
            "Built from commit $env:GITHUB_SHA. Runtime files are the unmodified ones from $upstream.zip.")
    }
    Step "zip $name" { 7z a -tzip -mx=3 -bso0 -bsp0 "$OutDir\$name.zip" $dir }
    Remove-Item -Recurse -Force $dir
    Write-Log ("$name.zip " + [math]::Round((Get-Item "$OutDir\$name.zip").Length / 1MB) + " MB")
}
