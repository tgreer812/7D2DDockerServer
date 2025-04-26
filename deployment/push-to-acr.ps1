# filepath: deployment/push-to-acr.ps1
# PowerShell script to build and push Docker image using Azure Container Registry (ACR) Tasks (no local Docker required)

# Determine config path
$possiblePaths = @("config/config.json", "../config/config.json")
$configPath = $possiblePaths | Where-Object { Test-Path $_ } | Select-Object -First 1
if (-not $configPath) {
    Write-Error "Config file not found in any expected location: $($possiblePaths -join ', ')"
    exit 1
}
$config = Get-Content $configPath | ConvertFrom-Json

# Load config values
$ACR_NAME = $config.acrName
$IMAGE_NAME = $config.imageName
$TAG = $config.tag

# Determine paths relative to this script
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Definition
$repoRoot = Resolve-Path "$scriptDir/.."
$dockerfilePath = Join-Path $repoRoot "docker/Dockerfile"

# Prepare image reference
$image = "$IMAGE_NAME`:$TAG"

# Queue ACR task build (build + push in cloud)
Write-Host "Queuing ACR Task build for $image in registry $ACR_NAME..."
az acr build --registry $ACR_NAME --image $image --file "$dockerfilePath" "$repoRoot"

Write-Host "ACR Task build submitted. Check Azure Portal or CLI for build status."