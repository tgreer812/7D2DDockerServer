#Requires -Version 5.1

<#
.SYNOPSIS
    Performs the initial one-time setup steps for the 7D2D Docker Server project.

.DESCRIPTION
    This script automates the following initial setup tasks:
    1. Copies 'config/config.json.example' to 'config/config.json'.
    2. Copies 'configs/serverconfig.default.xml' to 'configs/serverconfig.xml'.
    3. Runs the 'install-bicep.ps1' script to ensure Bicep CLI is installed.

    After running this script, you MUST manually edit the created 'config.json' 
    and 'configs/serverconfig.xml' files with your specific settings.

.NOTES
    File Name: initial_setup.ps1
    Author   : GitHub Copilot
    Date     : 2025-04-26
#>

[CmdletBinding()]
param()

# Determine repository root (assuming script is in 'deployment' folder)
$repoRoot = Resolve-Path (Join-Path $PSScriptRoot "..")
Write-Host "Repository Root: $repoRoot"

# Define source and destination paths relative to the repo root
$configExamplePath = Join-Path $repoRoot "config\config.json.example"
$configDestPath = Join-Path $repoRoot "config\config.json"

$serverConfigDefaultPath = Join-Path $repoRoot "configs\serverconfig.default.xml"
$serverConfigDestPath = Join-Path $repoRoot "configs\serverconfig.xml"

$installBicepScriptPath = Join-Path $repoRoot "deployment\install-bicep.ps1"

# --- Step 1: Copy config.json --- 
Write-Host "Step 1: Checking for config.json..."
if (Test-Path $configDestPath) {
    Write-Host "'config/config.json' already exists. Skipping copy."
} else {
    Write-Host "Copying '$($configExamplePath.Replace($repoRoot, "."))' to '$($configDestPath.Replace($repoRoot, "."))'..."
    try {
        Copy-Item -Path $configExamplePath -Destination $configDestPath -ErrorAction Stop
        Write-Host "Successfully copied config.json.example."
    } catch {
        Write-Error "Failed to copy '$configExamplePath'. Error: $_"
        exit 1
    }
}

# --- Step 2: Copy serverconfig.xml --- 
Write-Host "`nStep 2: Checking for serverconfig.xml..."
if (Test-Path $serverConfigDestPath) {
    Write-Host "'configs/serverconfig.xml' already exists. Skipping copy."
} else {
    Write-Host "Copying '$($serverConfigDefaultPath.Replace($repoRoot, "."))' to '$($serverConfigDestPath.Replace($repoRoot, "."))'..."
    try {
        Copy-Item -Path $serverConfigDefaultPath -Destination $serverConfigDestPath -ErrorAction Stop
        Write-Host "Successfully copied serverconfig.default.xml."
    } catch {
        Write-Error "Failed to copy '$serverConfigDefaultPath'. Error: $_"
        exit 1
    }
}

# --- Step 3: Install Bicep --- 
Write-Host "`nStep 3: Ensuring Bicep CLI is installed..."
try {
    & $installBicepScriptPath -ErrorAction Stop
    Write-Host "Bicep installation check completed."
} catch {
    Write-Error "Failed to run '$installBicepScriptPath'. Error: $_"
    # Decide if this should be fatal. Maybe Bicep is already installed via other means.
    # For now, let's make it non-fatal but warn.
    Write-Warning "Could not automatically run Bicep installation script. Please ensure Bicep CLI is installed manually if needed."
}

# --- Final Instructions --- 
Write-Host "`n-----------------------------------------"
Write-Host "Initial setup steps completed."
Write-Host "`nIMPORTANT NEXT STEPS:"
Write-Host "1. Edit '$($configDestPath.Replace($repoRoot, "."))' with your Azure deployment details (ACR name, password, etc.)."
Write-Host "2. Edit '$($serverConfigDestPath.Replace($repoRoot, "."))' with your desired 7 Days to Die server settings (name, password, game options)."
Write-Host "`nAfter editing the files, you can proceed with building the image ('./deployment/push-to-acr.ps1') and deploying ('./deployment/deploy-bicep.ps1')."
Write-Host "-----------------------------------------"
