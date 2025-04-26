#!/bin/bash
# Script to push the Docker image to Azure Container Registry

# Variables
CONFIG_PATH="../config/config.json"
ACR_NAME=$(jq -r '.acrName' "$CONFIG_PATH")
ACR_LOGIN_SERVER=$(jq -r '.acrLoginServer' "$CONFIG_PATH")
IMAGE_NAME=$(jq -r '.imageName' "$CONFIG_PATH")
TAG=$(jq -r '.tag' "$CONFIG_PATH")

# Log in to Azure
echo "Logging in to Azure..."
az login

# Log in to ACR
echo "Logging in to Azure Container Registry: $ACR_NAME..."
az acr login --name $ACR_NAME

# Tag the Docker image
echo "Tagging the Docker image..."
docker tag $IMAGE_NAME:$TAG $ACR_LOGIN_SERVER/$IMAGE_NAME:$TAG

# Push the image to ACR
echo "Pushing the Docker image to ACR..."
docker push $ACR_LOGIN_SERVER/$IMAGE_NAME:$TAG

echo "Image successfully pushed to ACR: $ACR_LOGIN_SERVER/$IMAGE_NAME:$TAG"