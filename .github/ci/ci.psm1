# Shared helpers for the CI steps: every command is logged to ci-out/<name>.log (published to the
# ci-logs branch) and its exit code is checked, so a failure says which command failed and why.

$script:Log = $null

function Use-Log([string]$Name) {
    $dir = Join-Path $env:GITHUB_WORKSPACE "ci-out"
    New-Item -ItemType Directory -Force -Path $dir | Out-Null
    $script:Log = Join-Path $dir "$Name.log"
}

function Write-Log([string]$Text) { $Text | Tee-Object -Append -FilePath $script:Log }

function Step([string]$What, [scriptblock]$Command) {
    Write-Log "== $What"
    $global:LASTEXITCODE = 0
    try {
        & $Command 2>&1 | ForEach-Object { "$_" } | Tee-Object -Append -FilePath $script:Log
    } catch {
        Write-Log "EXCEPTION in ${What}: $_"
        exit 1
    }
    if ($global:LASTEXITCODE -ne 0) {
        Write-Log "FAILED ($global:LASTEXITCODE): $What"
        exit 1
    }
}

# A shallow checkout of one commit (or tag) without the rest of the history.
function Get-GitCommit([string]$Url, [string]$Ref, [string]$Dir) {
    git init -q $Dir
    if ($LASTEXITCODE -ne 0) { return }
    git -C $Dir fetch -q --depth 1 $Url $Ref
    if ($LASTEXITCODE -ne 0) { return }
    git -C $Dir checkout -q FETCH_HEAD
}

# A shallow, sparse checkout of a tag: only the listed folders are written to disk.
function Get-GitSparse([string]$Url, [string]$Tag, [string]$Dir, [string[]]$Paths) {
    git clone -q --depth 1 --filter=blob:none --sparse --branch $Tag $Url $Dir
    if ($LASTEXITCODE -ne 0) { return }
    git -C $Dir sparse-checkout set @Paths
}

function Get-File([string]$Url, [string]$File) {
    New-Item -ItemType Directory -Force -Path (Split-Path -Parent $File) | Out-Null
    curl.exe -fsSL --retry 4 --retry-delay 5 -o $File $Url
}

Export-ModuleMember -Function Use-Log, Write-Log, Step, Get-GitCommit, Get-GitSparse, Get-File
