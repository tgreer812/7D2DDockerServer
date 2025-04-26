#Requires -Modules Az.Resources, Az.Storage, Az.ContainerRegistry

[CmdletBinding()]
param (
    [Parameter(Mandatory=$false)]
    [string]$ConfigPath = 'config/config.json',

    [Parameter(Mandatory=$false)]
    [ValidateSet('Incremental', 'Complete')]
    [string]$DeploymentMode = 'Incremental',

    [Parameter(Mandatory=$false)]
    [bool]$CopyConfigOnStart = $true # New parameter, defaults to true
)

# Construct absolute path for config if relative
if (-not [System.IO.Path]::IsPathRooted($ConfigPath)) {
    $ConfigPath = Join-Path $PSScriptRoot $ConfigPath
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

# Prepare parameters, ensuring boolean is passed correctly
$templateParameters = @{
    containerRegistryName = $config.acrName
    containerImageName = $config.imageName
    containerImageTag = $config.tag
    containerGroupName = $config.containerGroupName
    fileShareName = $config.fileShareName
    acrPassword = $config.acrPassword
    acrUsername = $config.acrName # Use acrName as username
    serverName = $config.serverName
    serverPassword = $config.serverPassword
    copyConfigOnStart = [System.Convert]::ToBoolean($CopyConfigOnStart) # Explicit bool conversion
}

New-AzResourceGroupDeployment `
    -ResourceGroupName $config.resourceGroup `
    -TemplateFile './azure/deploy.bicep' `
    -TemplateParameterObject $templateParameters `
    -Mode $DeploymentMode `
    -Verbose

Write-Host "Deployment script finished."
