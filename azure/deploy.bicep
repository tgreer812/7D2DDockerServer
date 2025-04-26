param location string = resourceGroup().location
param containerRegistryName string
param containerImageName string
param containerImageTag string
param containerGroupName string
param storageAccountName string = uniqueString(resourceGroup().id, '7dtdstorage')
param fileShareName string
@secure()
param acrPassword string
param acrUsername string
@secure()
param serverPassword string
param serverName string
param copyConfigOnStart bool = true // New parameter to control config copy

resource storageAccount 'Microsoft.Storage/storageAccounts@2022-09-01' = {
  name: storageAccountName
  location: location
  sku: {
    name: 'Standard_LRS'
  }
  kind: 'StorageV2'
  properties: {}
}

resource fileService 'Microsoft.Storage/storageAccounts/fileServices@2022-09-01' = {
  name: 'default'
  parent: storageAccount
}

resource fileShare 'Microsoft.Storage/storageAccounts/fileServices/shares@2022-09-01' = {
  parent: fileService
  name: fileShareName
  properties: {
    accessTier: 'TransactionOptimized'
  }
}

resource containerGroup 'Microsoft.ContainerInstance/containerGroups@2023-05-01' = { // Updated API version
  name: containerGroupName
  location: location
  properties: {
    containers: [
      {
        name: containerImageName
        properties: {
          image: '${containerRegistryName}.azurecr.io/${containerImageName}:${containerImageTag}'
          resources: {
            requests: {
              cpu: 2 // Increased for better performance
              memoryInGB: 4 // Increased for better performance
            }
          }
          ports: [
            {
              port: 26900
              protocol: 'UDP'
            }
            {
              port: 26901
              protocol: 'UDP'
            }
            {
              port: 26902
              protocol: 'UDP'
            }
            {
              port: 26903
              protocol: 'UDP'
            }
            {
              port: 8080 // Default web interface port
              protocol: 'TCP'
            }
            {
              port: 8081 // Telnet port
              protocol: 'TCP'
            }
            {
              port: 8082 // Control Panel port
              protocol: 'TCP'
            }
          ]
          environmentVariables: [
            {
              name: 'SERVERNAME'
              value: serverName
            }
            {
              name: 'SERVERPASSWORD'
              secureValue: serverPassword // Use secureValue for password
            }
            {
              name: 'COPY_CONFIG_ON_START'
              value: string(copyConfigOnStart) // Pass the parameter value
            }
          ]
          volumeMounts: [
            {
              name: '7dtddata'
              mountPath: '/data' // Mount point for persistent data
            }
          ]
        }
      }
    ]
    osType: 'Linux'
    ipAddress: {
      type: 'Public'
      ports: [
        {
          protocol: 'UDP'
          port: 26900
        }
        {
          protocol: 'UDP'
          port: 26901
        }
        {
          protocol: 'UDP'
          port: 26902
        }
        {
          protocol: 'UDP'
          port: 26903
        }
        {
          protocol: 'TCP'
          port: 8080 // Expose web interface port
        }
        {
          protocol: 'TCP'
          port: 8081 // Expose Telnet port
        }
        {
          protocol: 'TCP'
          port: 8082 // Expose Control Panel port
        }
      ]
      dnsNameLabel: containerGroupName // Optional: Add a DNS name label
    }
    imageRegistryCredentials: [
      {
        server: '${containerRegistryName}.azurecr.io'
        username: acrUsername
        password: acrPassword // Use secure parameter
      }
    ]
    volumes: [
      {
        name: '7dtddata'
        azureFile: {
          shareName: fileShare.name
          storageAccountName: storageAccount.name
          storageAccountKey: storageAccount.listKeys().keys[0].value
        }
      }
    ]
    restartPolicy: 'OnFailure' // Optional: Set restart policy
  }
}

output containerGroupNameOutput string = containerGroupName
// output containerGroupIp string = containerGroup.properties.ipAddress.ip // Removed/Commented out due to DeploymentOutputEvaluationFailed error
output containerGroupFqdn string = containerGroup.properties.ipAddress.fqdn
