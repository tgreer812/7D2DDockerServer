#Requires -Modules Az.Resources, Az.Storage, Az.ContainerRegistry
#Requires -Version 5.1

<#
.SYNOPSIS
    Deploys the 7D2D Docker Server to Azure using Bicep.

.DESCRIPTION
    This script reads configuration from config/config.json, checks/creates the
    specified resource group, prepares a cloud-init script with injected values
    (including a systemd service definition), and then deploys the Azure resources
    defined in azure/deploy.bicep using the New-AzResourceGroupDeployment cmdlet.

.NOTES
    File Name: deploy-bicep.ps1
    Author   : GitHub Copilot
    Date     : 2025-05-01
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

# --- Define Configuration Paths ---
# Construct absolute path for config if relative path was provided *as parameter*
if ($PSBoundParameters.ContainsKey('ConfigPath') -and (-not [System.IO.Path]::IsPathRooted($ConfigPath))) {
    Write-Warning "Relative ConfigPath parameter provided. Resolving from original location. Consider using default or absolute path."
    $ConfigPath = Resolve-Path -Path $ConfigPath -ErrorAction SilentlyContinue
} elseif (-not $PSBoundParameters.ContainsKey('ConfigPath')) {
    # Resolve the default path relative to the repo root
    $ConfigPath = Resolve-Path -Path $ConfigPath -ErrorAction SilentlyContinue
}
$cloudInitTemplatePath = Join-Path $repoRoot 'deployment/cloud-init.txt'
$serviceTemplatePath = Join-Path $repoRoot 'deployment/7dtd.service.template'
$bicepTemplatePath = Join-Path $repoRoot 'azure/deploy.bicep'

# --- Read Configuration ---
if (-not (Test-Path $ConfigPath)) {
    Write-Error "Configuration file not found at $ConfigPath"
    exit 1
}
$config = Get-Content $ConfigPath | ConvertFrom-Json

# --- Validate Configuration ---
# Required keys for VM deployment (removed containerName)
$requiredKeys = @('acrName', 'acrLoginServer', 'imageName', 'tag', 'resourceGroup', 'location', 'vmName', 'adminUsername', 'adminPassword', 'acrPassword')
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

# --- Check/Create Resource Group ---
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
        $config.location = $rg.Location # Update location to match existing RG
    } else {
        Write-Host "Resource Group '$($config.resourceGroup)' already exists in location '$($config.location)'."
    }
}

# --- Prepare Service Content and Cloud-Init ---
# Read and process the systemd service template
if (-not (Test-Path $serviceTemplatePath)) {
    Write-Error "Systemd service template not found at $serviceTemplatePath"
    exit 1
}
$serviceContent = Get-Content $serviceTemplatePath -Raw
$serviceContent = $serviceContent -replace '<acrLoginServer>', $config.acrLoginServer
$serviceContent = $serviceContent -replace '<acrUsername>', $config.acrName
$serviceContent = $serviceContent -replace '<acrPassword>', $config.acrPassword
$serviceContent = $serviceContent -replace '<imageName>', $config.imageName
$serviceContent = $serviceContent -replace '<imageTag>', $config.tag

# Base64 encode the processed service content for safe transport
$base64ServiceContent = [Convert]::ToBase64String([System.Text.Encoding]::UTF8.GetBytes($serviceContent))

# Define the command for the Custom Script Extension
# Decodes the service file, writes it, reloads systemd, enables, checks docker, & starts service
$commandToExecute = "echo '${base64ServiceContent}' | base64 --decode | sudo tee /etc/systemd/system/7dtd.service > /dev/null && sudo systemctl daemon-reload && sudo systemctl enable 7dtd.service && sudo systemctl is-active --quiet docker.service && sudo systemctl start 7dtd.service"

# Read the simplified cloud-init template
if (-not (Test-Path $cloudInitTemplatePath)) {
    Write-Error "Cloud-init template not found at $cloudInitTemplatePath"
    exit 1
}
$cloudInitRaw = Get-Content $cloudInitTemplatePath -Raw
$cloudInitBase64 = [Convert]::ToBase64String([System.Text.Encoding]::UTF8.GetBytes($cloudInitRaw))

# --- Deploy Bicep template ---
Write-Host "Starting Bicep deployment to Resource Group '$($config.resourceGroup)'..."

if (-not (Test-Path $bicepTemplatePath)) {
    Write-Error "Bicep template file not found at expected location: $bicepTemplatePath"
    exit 1
}

# Prepare parameters for Bicep deployment (including the new command)
$deployParams = @{
    ResourceGroupName    = $config.resourceGroup
    TemplateFile         = $bicepTemplatePath
    location             = $config.location # Use potentially updated location
    vmName               = $config.vmName
    adminUsername        = $config.adminUsername
    adminPassword        = $secureAdminPassword
    customDataBase64     = $cloudInitBase64
    customScriptCommand  = $commandToExecute # Pass the command
    Mode                 = $DeploymentMode
}

Write-Host "Deployment Parameters:"
$deployParams.GetEnumerator() | ForEach-Object {
    if ($_.Name -ne 'adminPassword') {
        Write-Host "  $($_.Name): $($_.Value)"
    } else {
        Write-Host "  $($_.Name): [secure]"
    }
}

try {
    # Validate the deployment first
    Write-Host "Validating Bicep deployment..."
    # Pass parameters individually to Test-AzResourceGroupDeployment
    Test-AzResourceGroupDeployment -ResourceGroupName $config.resourceGroup `
        -TemplateFile $bicepTemplatePath `
        -location $config.location `
        -vmName $config.vmName `
        -adminUsername $config.adminUsername `
        -adminPassword $secureAdminPassword `
        -customDataBase64 $cloudInitBase64 `
        -customScriptCommand $commandToExecute `
        -Mode $DeploymentMode `
        -ErrorAction Stop
    Write-Host "Validation successful. Proceeding with deployment..."

    # Ensure Bicep uses the base64-encoded cloud-init content and the command
    New-AzResourceGroupDeployment @deployParams -Verbose -ErrorAction Stop
    Write-Host "Bicep deployment completed successfully."
} catch {
    Write-Error "Bicep deployment failed. Error: $_"
    exit 1
} finally {
    Write-Host "Deployment script finished."
}
