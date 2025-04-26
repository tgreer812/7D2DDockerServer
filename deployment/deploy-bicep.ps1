#Requires -Modules Az.Resources, Az.Storage, Az.ContainerRegistry

[CmdletBinding()]
param (
    # Default path is now relative to the repo root
    [Parameter(Mandatory=$false)]
    [string]$ConfigPath = 'config/config.json',

    [Parameter(Mandatory=$false)]
    [ValidateSet('Incremental', 'Complete')]
    [string]$DeploymentMode = 'Incremental',

    [Parameter(Mandatory=$false)]
    [bool]$CopyConfigOnStart = $true,

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

# Validate required config properties
$requiredProperties = @('resourceGroup', 'acrName', 'imageName', 'tag', 'containerGroupName', 'fileShareName', 'acrPassword', 'serverName', 'serverPassword')
foreach ($prop in $requiredProperties) {
    if (-not $config.$prop) {
        Write-Error "Required property '$prop' missing in configuration file $ConfigPath"
        exit 1
    }
}

# Deploy Bicep template
Write-Host "Starting Bicep deployment in resource group '$($config.resourceGroup)'..."

# Prepare secure parameters
$secureAcrPassword = (ConvertTo-SecureString -String $config.acrPassword -AsPlainText -Force)
$secureServerPassword = (ConvertTo-SecureString -String $config.serverPassword -AsPlainText -Force)

# Debug: Output the parameters being passed to Bicep
Write-Host "DEBUG: Parameters to be passed directly:"
Write-Host "  containerRegistryName: $($config.acrName)"
Write-Host "  containerImageName: $($config.imageName)"
Write-Host "  containerImageTag: $($config.tag)"
Write-Host "  containerGroupName: $($config.containerGroupName)"
Write-Host "  fileShareName: $($config.fileShareName)"
Write-Host "  acrUsername: $($config.acrName)"
Write-Host "  serverName: $($config.serverName)"
Write-Host "  copyConfigOnStart: $([System.Convert]::ToBoolean($CopyConfigOnStart))"
Write-Host "  acrPassword Type: $($secureAcrPassword.GetType().FullName)"
Write-Host "  serverPassword Type: $($secureServerPassword.GetType().FullName)"

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
    -copyConfigOnStart ([System.Convert]::ToBoolean($CopyConfigOnStart)) `
    -acrPassword $secureAcrPassword `
    -serverPassword $secureServerPassword `
    -Mode $DeploymentMode `
    -Verbose

Write-Host "Deployment script finished."
