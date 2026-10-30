<#
.SYNOPSIS
    Deploys OldSchoolConsumables addon to the live World of Warcraft retail installation.

.DESCRIPTION
    Copies the TOC, Lua source modules, and audio assets to the target WoW AddOns directory:
    "C:\Program Files (x86)\World of Warcraft\_retail_\Interface\AddOns\OldSchoolConsumables"
    Verifies that all files exist and match source byte counts.
#>

[CmdletBinding()]
param(
    [string]$SourceDir,
    [string]$TargetDir = "C:\Program Files (x86)\World of Warcraft\_retail_\Interface\AddOns\OldSchoolConsumables"
)

$ErrorActionPreference = "Stop"

if (-not $SourceDir) {
    if ($PSScriptRoot) {
        $SourceDir = $PSScriptRoot
    } elseif ($MyInvocation.MyCommand.Path) {
        $SourceDir = Split-Path -Parent $MyInvocation.MyCommand.Path
    } else {
        $SourceDir = (Resolve-Path "projects/old-school-consumables").Path
    }
}

Write-Host "=================================================================" -ForegroundColor Cyan
Write-Host " OldSchoolConsumables Deployment Engine (WoW Retail 12.0+)" -ForegroundColor Cyan
Write-Host "=================================================================" -ForegroundColor Cyan
Write-Host "Source: $SourceDir"
Write-Host "Target: $TargetDir"
Write-Host ""

# 1. Ensure Target Directories Exist
$TargetSoundsDir = Join-Path $TargetDir "Sounds"
if (-not (Test-Path $TargetDir)) {
    Write-Host "[1/4] Creating addon root directory: $TargetDir" -ForegroundColor Yellow
    New-Item -ItemType Directory -Force -Path $TargetDir | Out-Null
} else {
    Write-Host "[1/4] Addon root directory exists: $TargetDir" -ForegroundColor Green
}

if (-not (Test-Path $TargetSoundsDir)) {
    Write-Host "      Creating Sounds subfolder: $TargetSoundsDir" -ForegroundColor Yellow
    New-Item -ItemType Directory -Force -Path $TargetSoundsDir | Out-Null
} else {
    Write-Host "      Sounds subfolder exists: $TargetSoundsDir" -ForegroundColor Green
}

# 2. File Manifests
$RootFiles = @(
    "OldSchoolConsumables.toc",
    "Database.lua",
    "AudioEngine.lua",
    "OverheadDisplay.lua",
    "TriggerEngine.lua",
    "UI_DraggableWindow.lua",
    "UI_BlizzardSettings.lua",
    "Core.lua"
)

$SoundFiles = @(
    "potion.ogg",
    "potion.wav",
    "food.ogg",
    "food.wav",
    "2401.wav",
    "2393.wav"
)

# 3. Copy Files
Write-Host "`n[2/4] Deploying core files..." -ForegroundColor Yellow
foreach ($file in $RootFiles) {
    $src = Join-Path $SourceDir $file
    $dst = Join-Path $TargetDir $file
    if (-not (Test-Path $src)) {
        throw "Source file missing: $src"
    }
    Copy-Item -Path $src -Destination $dst -Force
    $size = (Get-Item $dst).Length
    Write-Host "  -> Copied $file ($size bytes)" -ForegroundColor Gray
}

Write-Host "`n[3/4] Deploying sound assets..." -ForegroundColor Yellow
$SourceSoundsDir = Join-Path $SourceDir "Sounds"
foreach ($file in $SoundFiles) {
    $src = Join-Path $SourceSoundsDir $file
    $dst = Join-Path $TargetSoundsDir $file
    if (-not (Test-Path $src)) {
        throw "Source sound asset missing: $src"
    }
    Copy-Item -Path $src -Destination $dst -Force
    $size = (Get-Item $dst).Length
    Write-Host "  -> Copied Sounds/$file ($size bytes)" -ForegroundColor Gray
}

# 4. Verification & Byte Count Audit
Write-Host "`n[4/4] Validating deployed files & byte counts..." -ForegroundColor Yellow
$allPassed = $true
$totalBytes = 0

foreach ($file in $RootFiles) {
    $src = Join-Path $SourceDir $file
    $dst = Join-Path $TargetDir $file
    if (-not (Test-Path $dst)) {
        Write-Host "  [FAIL] Missing file: $dst" -ForegroundColor Red
        $allPassed = $false
        continue
    }
    $srcSize = (Get-Item $src).Length
    $dstSize = (Get-Item $dst).Length
    if ($srcSize -ne $dstSize) {
        Write-Host "  [FAIL] Size mismatch on $($file): Source=$srcSize vs Target=$dstSize" -ForegroundColor Red
        $allPassed = $false
    } else {
        $totalBytes += $dstSize
    }
}

foreach ($file in $SoundFiles) {
    $src = Join-Path $SourceSoundsDir $file
    $dst = Join-Path $TargetSoundsDir $file
    if (-not (Test-Path $dst)) {
        Write-Host "  [FAIL] Missing file: $dst" -ForegroundColor Red
        $allPassed = $false
        continue
    }
    $srcSize = (Get-Item $src).Length
    $dstSize = (Get-Item $dst).Length
    if ($srcSize -ne $dstSize) {
        Write-Host "  [FAIL] Size mismatch on Sounds/$($file): Source=$srcSize vs Target=$dstSize" -ForegroundColor Red
        $allPassed = $false
    } else {
        $totalBytes += $dstSize
    }
}

if (-not $allPassed) {
    throw "Deployment verification failed! One or more files missing or corrupt."
}

Write-Host "`n=================================================================" -ForegroundColor Green
Write-Host " DEPLOYMENT SUCCESSFUL!" -ForegroundColor Green
Write-Host " Addon installed to: $TargetDir" -ForegroundColor Green
Write-Host (" Verified {0} files totaling {1:N0} bytes." -f ($RootFiles.Count + $SoundFiles.Count), $totalBytes) -ForegroundColor Green
Write-Host " Ready for World of Warcraft: Midnight (12.0+)!" -ForegroundColor Green
Write-Host "=================================================================" -ForegroundColor Green
