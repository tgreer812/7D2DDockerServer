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
if ($PSBoundParameters.ContainsKey('ConfigPath') -and (-not [System.IO.Path]::IsPathRooted($ConfigPath))) {
    Write-Warning "Relative ConfigPath parameter provided. Resolving from original location. Consider using default or absolute path."
    $ConfigPath = Resolve-Path -Path $ConfigPath -ErrorAction SilentlyContinue
} elseif (-not $PSBoundParameters.ContainsKey('ConfigPath')) {
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
# Required keys for VM deployment
$requiredKeys = @('acrName', 'acrLoginServer', 'imageName', 'tag', 'resourceGroup', 'location', 'vmName', 'adminUsername', 'adminPassword')
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

# Secure password
$secureAdminPassword = ConvertTo-SecureString -String $config.adminPassword -AsPlainText -Force

# Check/Create Resource Group
Write-Host "Checking for Resource Group '$($config.resourceGroup)' in location '$($config.location)'..."
$rg = Get-AzResourceGroup -Name $config.resourceGroup -ErrorAction SilentlyContinue

if ($null -eq $rg) {
    Write-Host "Resource Group '$($config.resourceGroup)' not found. Creating..."
    try {
        New-AzResourceGroup -Name $config.resourceGroup -Location $config.location -ErrorAction Stop | Out-Null
        Write-Host "Resource Group '$($config.resourceGroup)' created successfully."
    } catch {
        Write-Error "Failed to create Resource Group '$($config.resourceGroup)'. Error: $_"
        exit 1
    }
} else {
    if ($rg.Location -ne $config.location) {
        Write-Warning "Resource Group '$($config.resourceGroup)' exists but in location '$($rg.Location)', while config specifies '$($config.location)'. Deployment will proceed to the existing group's location."
        $config.location = $rg.Location
    } else {
        Write-Host "Resource Group '$($config.resourceGroup)' already exists in location '$($config.location)'.."
    }
}

# --- Prepare cloud-init with ACR credentials and image info ---
$cloudInitTemplatePath = Join-Path $repoRoot 'deployment/cloud-init.txt'
$cloudInitTempPath = Join-Path $repoRoot 'deployment/cloud-init-temp.txt'

$cloudInitContent = Get-Content $cloudInitTemplatePath -Raw
$cloudInitContent = $cloudInitContent -replace '<acrLoginServer>', $config.acrLoginServer
$cloudInitContent = $cloudInitContent -replace '<acrUsername>', $config.acrName
$cloudInitContent = $cloudInitContent -replace '<acrPassword>', $config.acrPassword
$cloudInitContent = $cloudInitContent -replace '<imageName>', $config.imageName
$cloudInitContent = $cloudInitContent -replace '<imageTag>', $config.tag

Set-Content -Path $cloudInitTempPath -Value $cloudInitContent

# Deploy Bicep template for VM
Write-Host "Starting Bicep deployment to Resource Group '$($config.resourceGroup)'..."

$templateFilePath = 'azure/deploy.bicep'
if (-not (Test-Path $templateFilePath)) {
    Write-Error "Bicep template file not found at expected location: $templateFilePath (relative to repo root)"
    exit 1
}

$deployParams = @{
    ResourceGroupName = $config.resourceGroup
    TemplateFile = $templateFilePath
    location = $config.location
    vmName = $config.vmName
    adminUsername = $config.adminUsername
    adminPassword = $secureAdminPassword
    Mode = $DeploymentMode
}

# Patch Bicep to use the temp cloud-init file
# We'll copy the temp file to the same relative path Bicep expects
$expectedCloudInitPath = Join-Path $repoRoot 'deployment/cloud-init.txt'
Copy-Item -Path $cloudInitTempPath -Destination $expectedCloudInitPath -Force

Write-Host "Deployment Parameters:"
$deployParams.GetEnumerator() | ForEach-Object { 
    if ($_.Name -ne 'adminPassword') {
        Write-Host "  $($_.Name): $($_.Value)" 
    } else {
        Write-Host "  $($_.Name): [secure]"
    }
}

try {
    New-AzResourceGroupDeployment @deployParams -Verbose -ErrorAction Stop
    Write-Host "Bicep deployment completed successfully."
} catch {
    Write-Error "Bicep deployment failed. Error: $_"
    exit 1
}

# Clean up temp file
Remove-Item $cloudInitTempPath -ErrorAction SilentlyContinue

Write-Host "Deployment script finished."
