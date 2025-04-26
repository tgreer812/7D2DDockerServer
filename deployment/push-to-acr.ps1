# filepath: deployment/push-to-acr.ps1
# PowerShell script to build and push Docker image using Azure Container Registry (ACR) Tasks (no local Docker required)

#Requires -Modules Az.ContainerRegistry

[CmdletBinding()]
param (
    # Default path is now relative to the repo root
    [Parameter(Mandatory=$false)]
    [string]$ConfigPath = 'config/config.json'
)

# Determine repository root (assuming script is in 'deployment' folder)
$repoRoot = Resolve-Path (Join-Path $PSScriptRoot "..")
Write-Verbose "Setting working directory to repository root: $repoRoot"
Set-Location $repoRoot

# Construct absolute path for config if relative path was provided *as parameter*
if ($PSBoundParameters.ContainsKey('ConfigPath') -and (-not [System.IO.Path]::IsPathRooted($ConfigPath))) {
    $ConfigPath = Resolve-Path -Path $ConfigPath -ErrorAction SilentlyContinue
} elseif (-not $PSBoundParameters.ContainsKey('ConfigPath')) {
    # Resolve the default path relative to the repo root
    $ConfigPath = Resolve-Path -Path $ConfigPath -ErrorAction SilentlyContinue
}

# Check if config file exists
if (-not $ConfigPath) {
    Write-Error "Config file not found at expected location: $ConfigPath"
    exit 1
}
$config = Get-Content $ConfigPath | ConvertFrom-Json

# Validate required config properties
$ACR_NAME = $config.acrName
$IMAGE_NAME = $config.imageName
$TAG = $config.tag
$image = "${IMAGE_NAME}:${TAG}"
$dockerfilePath = 'docker/Dockerfile' # Path relative to repo root

# Check if Dockerfile exists
if (-not (Test-Path $dockerfilePath)) {
    Write-Error "Dockerfile not found at expected location: $dockerfilePath (relative to $repoRoot)"
    exit 1
}

# Build and push using Azure Container Registry Tasks
Write-Host "Starting ACR build for image '$image' in registry '$ACR_NAME'..."
Write-Host "Using Dockerfile: $dockerfilePath"
Write-Host "Build context: $repoRoot"

az acr build --registry $ACR_NAME --image $image `
             --file $dockerfilePath `
             "." # Build context is the current directory (repo root)

Write-Host "ACR build script finished."