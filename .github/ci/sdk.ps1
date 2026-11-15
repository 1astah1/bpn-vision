# Vendor SDKs for the full build, from their public sources, into $env:SDK (cached between runs).
# Each block is skipped when its marker file is already there. Not public, so not built: NVIDIA Optical
# Flow SDK 5.0.7 (developer login) and the Magewell capture SDK.
param()
$ErrorActionPreference = "Stop"
Import-Module "$env:GITHUB_WORKSPACE\.github\ci\ci.psm1"
Use-Log "sdk"
$sdk = $env:SDK
New-Item -ItemType Directory -Force -Path $sdk, "$sdk\_dl" | Out-Null

# NVIDIA DLSS SDK 310.7.0 (NGX headers and the static NGX core used by the experimental DLSS paths).
$dlss = "$sdk\DLSS_SDK_310.7.0"
if (-not (Test-Path "$dlss\include\nvsdk_ngx.h")) {
    Step "DLSS SDK 310.7.0" { Get-GitSparse "https://github.com/NVIDIA/DLSS.git" "v310.7.0" $dlss @("include", "lib/Windows_x86_64") }
}

# Intel XeSS SDK 3.0.2 (XeSS SR and XeSS frame generation headers and import libraries).
$xess = "$sdk\xess-3.0.2"
if (-not (Test-Path "$xess\inc\xess_fg\xefg_swapchain_d3d12.h")) {
    Step "XeSS 3.0.2 download" { Get-File "https://github.com/intel/xess/releases/download/v3.0.2/XeSS_SDK_3.0.2.zip" "$sdk\_dl\xess.zip" }
    New-Item -ItemType Directory -Force -Path $xess | Out-Null
    Step "XeSS 3.0.2 extract" { tar -xf "$sdk\_dl\xess.zip" -C $xess }
}

# AMD FidelityFX SDK 2.3.0 (FSR 3.1/4 upscaling and frame generation through the signed DLLs).
$ffx2 = "$sdk\FidelityFX-SDK-2.3.0"
if (-not (Test-Path "$ffx2\Kits\FidelityFX\framegeneration\include\dx12\ffx_api_framegeneration_dx12.h")) {
    Step "FidelityFX 2.3.0" { Get-GitSparse "https://github.com/GPUOpen-LibrariesAndSDKs/FidelityFX-SDK.git" "v2.3.0" $ffx2 @("Kits/FidelityFX") }
    Step "FidelityFX 2.3.0 LFS" { git -C $ffx2 lfs pull --include "Kits/FidelityFX/**" }
}

# AMD FidelityFX SDK 1.1.4 (optical flow for frame generation): built from source, Release only.
$ffx1 = "$sdk\FidelityFX-SDK-1.1.4"
if (-not (Test-Path "$ffx1\sdk\bin\ffx_sdk\ffx_opticalflow_x64.lib")) {
    Step "FidelityFX 1.1.4 download" { Get-File "https://github.com/GPUOpen-LibrariesAndSDKs/FidelityFX-SDK/releases/download/v1.1.4/FidelityFX-SDK-v1.1.4.zip" "$sdk\_dl\ffx1.zip" }
    New-Item -ItemType Directory -Force -Path $ffx1 | Out-Null
    Step "FidelityFX 1.1.4 extract" { tar -xf "$sdk\_dl\ffx1.zip" -C $ffx1 sdk }
    Step "FidelityFX 1.1.4 configure" {
        cmake -S "$ffx1\sdk" -B "$ffx1\sdk\build" -G "Visual Studio 17 2022" -A x64 -DFFX_API_BACKEND=DX12_X64 -DFFX_ALL=ON -DFFX_AUTO_COMPILE_SHADERS=1
    }
    Step "FidelityFX 1.1.4 build" { cmake --build "$ffx1\sdk\build" --config Release --parallel 4 }
    Step "FidelityFX 1.1.4 libraries" { Get-ChildItem "$ffx1\sdk\bin" -Recurse -Filter *.lib | ForEach-Object { $_.FullName } }
    Remove-Item -Recurse -Force "$ffx1\sdk\build" -ErrorAction SilentlyContinue
}

# CUDA driver API header (cuda.h) for the native frame-generation path; headers only.
$cuda = "$sdk\cuda"
if (-not (Test-Path "$cuda\include\cuda.h")) {
    $name = "cuda_cudart-windows-x86_64-13.0.96-archive"
    Step "CUDA headers download" { Get-File "https://developer.download.nvidia.com/compute/cuda/redist/cuda_cudart/windows-x86_64/$name.zip" "$sdk\_dl\cudart.zip" }
    Step "CUDA headers extract" { tar -xf "$sdk\_dl\cudart.zip" -C "$sdk\_dl" }
    New-Item -ItemType Directory -Force -Path $cuda | Out-Null
    Step "CUDA headers copy" { Copy-Item -Recurse -Force "$sdk\_dl\$name\include" "$cuda\include" }
}

# Blackmagic DeckLink API (IDL only), as OBS Studio 31 ships it.
$decklink = "$sdk\decklink"
if (-not (Test-Path "$decklink\DeckLinkAPI.idl")) {
    Step "DeckLink IDL (OBS 31.1.2)" { Get-GitSparse "https://github.com/obsproject/obs-studio.git" "31.1.2" "$sdk\_dl\obs" @("plugins/decklink/win/decklink-sdk") }
    New-Item -ItemType Directory -Force -Path $decklink | Out-Null
    Step "DeckLink IDL copy" { Copy-Item -Force "$sdk\_dl\obs\plugins\decklink\win\decklink-sdk\*" $decklink }
}

# AMD RDNA3 NR worker network source, as Veyra publishes it with each release.
$rdna3 = "$sdk\rdna3-network"
if (-not (Test-Path "$rdna3\runtime\core\network.cpp")) {
    Step "RDNA3 network source" { Get-File "https://github.com/Likely7/Veyra-NRVideo/releases/download/v2.1.6-sources/Veyra-2.1.6-rdna3-network-source.zip" "$sdk\_dl\rdna3.zip" }
    Step "RDNA3 extract" { tar -xf "$sdk\_dl\rdna3.zip" -C $sdk }
}

# VB-CABLE Pack46, embedded for the optional offline driver install (the build checks its SHA-256).
# Optional: when the download fails the build simply leaves the offline installer out.
$vb = "$sdk\VBCABLE_Driver_Pack46.zip"
if (-not (Test-Path $vb)) {
    curl.exe -fsSL --retry 3 -o $vb "https://download.vb-audio.com/Download_CABLE/VBCABLE_Driver_Pack46.zip" 2>&1 | ForEach-Object { Write-Log "$_" }
    if ($LASTEXITCODE -ne 0) { Write-Log "VB-CABLE Pack46 download failed ($LASTEXITCODE): left out"; Remove-Item -Force $vb -ErrorAction SilentlyContinue; $global:LASTEXITCODE = 0 }
}
if (Test-Path $vb) { Write-Log ("VB-CABLE sha256 " + (Get-FileHash -Algorithm SHA256 $vb).Hash.ToLower()) }

Remove-Item -Recurse -Force "$sdk\_dl" -ErrorAction SilentlyContinue
Write-Log "SDK ready"
