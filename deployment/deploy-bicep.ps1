#Requires -Modules Az.Resources, Az.Storage, Az.ContainerRegistry
#Requires -Version 5.1

<#
.SYNOPSIS
    Deploys the 7D2D Docker Server to Azure using Bicep.

.DESCRIPTION
    This script reads configuration from config/config.json, checks/creates the 
    specified resource group, and then deploys the Azure resources defined in 
    azure/deploy.bicep using the New-AzResourceGroupDeployment cmdlet.

.NOTES
    File Name: deploy-bicep.ps1
    Author   : GitHub Copilot
    Date     : 2025-04-26
#>

[CmdletBinding()]
param (
    # Default path is now relative to the repo root
    [Parameter(Mandatory=$false)]
    [string]$ConfigPath = 'config/config.json',

    [Parameter(Mandatory=$false)]
    [ValidateSet('Incremental', 'Complete')]
    [string]$DeploymentMode = 'Incremental',

    [Parameter(Mandatory=$false)]
    [switch]$Authenticate
)

# Azure authentication logic
if ($Authenticate) {
    Write-Host "--authenticate flag detected. Launching device code authentication..."
    Connect-AzAccount -DeviceCode
} elseif (-not (Get-AzContext)) {
    Write-Host "You are not logged in to Azure. Please run this script with the -Authenticate flag to log in using device code authentication, or log in manually using Connect-AzAccount."
    exit 1
}

# Determine repository root (assuming script is in 'deployment' folder)
$repoRoot = Resolve-Path (Join-Path $PSScriptRoot "..")
Write-Verbose "Setting working directory to repository root: $repoRoot"
Set-Location $repoRoot

# Construct absolute path for config if relative path was provided *as parameter*
# If default is used, it's already relative to repo root.
if ($PSBoundParameters.ContainsKey('ConfigPath') -and (-not [System.IO.Path]::IsPathRooted($ConfigPath))) {
    # If a relative path was passed in, resolve it against the original location before changing directory
    # This is less common, usually user provides full path or relies on default
    Write-Warning "Relative ConfigPath parameter provided. Resolving from original location. Consider using default or absolute path."
    $ConfigPath = Resolve-Path -Path $ConfigPath -ErrorAction SilentlyContinue
} elseif (-not $PSBoundParameters.ContainsKey('ConfigPath')) {
    # Resolve the default path relative to the repo root
    $ConfigPath = Resolve-Path -Path $ConfigPath -ErrorAction SilentlyContinue
}

# Check if config file exists
if (-not (Test-Path $ConfigPath)) {
    Write-Error "Configuration file not found at $ConfigPath"
    exit 1
}

# Read configuration from JSON file
$config = Get-Content $ConfigPath | ConvertFrom-Json

# --- Validate Configuration ---
# Required keys
$requiredKeys = @('acrName', 'acrLoginServer', 'imageName', 'tag', 'containerGroupName', 'fileShareName', 'serverName', 'serverPassword', 'resourceGroup', 'acrPassword', 'location') 
# Optional keys with dependencies
$optionalKeys = @('adminPrincipalId', 'adminPrincipalType')

$missingRequiredKeys = @()
foreach ($key in $requiredKeys) {
    if (-not $config.PSObject.Properties.Name.Contains($key) -or [string]::IsNullOrWhiteSpace($config.$key)) {
        $missingRequiredKeys += $key
    }
}

if ($missingRequiredKeys.Count -gt 0) {
    Write-Error "Missing or empty required configuration values in '$ConfigPath': $($missingRequiredKeys -join ', ')"
    exit 1
}

# Validate optional adminPrincipalId/Type - if ID is present, Type must also be present
$adminPrincipalId = $null
$adminPrincipalType = 'User' # Default value used in Bicep if not provided
if ($config.PSObject.Properties.Name.Contains('adminPrincipalId') -and (-not [string]::IsNullOrWhiteSpace($config.adminPrincipalId))) {
    $adminPrincipalId = $config.adminPrincipalId
    if ($config.PSObject.Properties.Name.Contains('adminPrincipalType') -and (-not [string]::IsNullOrWhiteSpace($config.adminPrincipalType))) {
        $adminPrincipalType = $config.adminPrincipalType
    } else {
        # If ID is set but Type is missing/empty, use the default and warn
        Write-Warning "'adminPrincipalId' is set in config, but 'adminPrincipalType' is missing or empty. Defaulting to 'User'."
    }
} elseif ($config.PSObject.Properties.Name.Contains('adminPrincipalType') -and (-not [string]::IsNullOrWhiteSpace($config.adminPrincipalType))) {
    # If Type is set but ID is missing/empty, warn that Type will be ignored
    Write-Warning "'adminPrincipalType' is set in config, but 'adminPrincipalId' is missing or empty. The 'adminPrincipalType' setting will be ignored."
}

# Secure passwords
$secureAcrPassword = ConvertTo-SecureString -String $config.acrPassword -AsPlainText -Force
$secureServerPassword = ConvertTo-SecureString -String $config.serverPassword -AsPlainText -Force

# Check/Create Resource Group
Write-Host "Checking for Resource Group '$($config.resourceGroup)' in location '$($config.location)'..."
$rg = Get-AzResourceGroup -Name $config.resourceGroup -ErrorAction SilentlyContinue # Check existence first

if ($null -eq $rg) {
    Write-Host "Resource Group '$($config.resourceGroup)' not found. Creating..."
    try {
        # Create the resource group using the specified location
        New-AzResourceGroup -Name $config.resourceGroup -Location $config.location -ErrorAction Stop | Out-Null
        Write-Host "Resource Group '$($config.resourceGroup)' created successfully."
    } catch {
        Write-Error "Failed to create Resource Group '$($config.resourceGroup)'. Error: $_"
        exit 1
    }
} else {
    # Verify existing RG location matches config location
    if ($rg.Location -ne $config.location) {
        Write-Warning "Resource Group '$($config.resourceGroup)' exists but in location '$($rg.Location)', while config specifies '$($config.location)'. Deployment will proceed to the existing group's location."
        # Update the location variable to match the actual RG location for the deployment command
        $config.location = $rg.Location
    } else {
        Write-Host "Resource Group '$($config.resourceGroup)' already exists in location '$($config.location)'.."
    }
}

# Deploy Bicep template
Write-Host "Starting Bicep deployment to Resource Group '$($config.resourceGroup)'..."

# Template file path is now relative to repo root
$templateFilePath = 'azure/deploy.bicep'
if (-not (Test-Path $templateFilePath)) {
    Write-Error "Bicep template file not found at expected location: $templateFilePath (relative to $repoRoot)"
    exit 1
}

# Pass ALL parameters directly by name
    New-AzResourceGroupDeployment `
        -ResourceGroupName $config.resourceGroup `
        -TemplateFile $templateFilePath `
        -containerRegistryName $config.acrName `
        -containerImageName $config.imageName `
        -containerImageTag $config.tag `
        -containerGroupName $config.containerGroupName `
        -fileShareName $config.fileShareName `
        -acrUsername $config.acrName `
        -serverName $config.serverName `
        -acrPassword $secureAcrPassword `
        -adminPrincipalId $config.adminPrincipalId `
        -serverPassword $secureServerPassword `
        -Mode $DeploymentMode `
        -Verbose

Write-Host "Deployment script finished."
