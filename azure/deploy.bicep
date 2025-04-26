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

// Optional: Specify the Principal ID (Object ID) of a user, group, or service principal
// to grant elevated SMB share access (Storage File Data SMB Share Elevated Contributor)
// for managing permissions directly on the file share. Leave empty to skip role assignment.
param adminPrincipalId string = ''

// Optional: Specify the type of the principal ID provided above.
// Required if adminPrincipalId is set. Defaults to 'User'.
@allowed([
  'User'
  'Group'
  'ServicePrincipal'
  'ForeignGroup'
  'Device'
])
param adminPrincipalType string = 'User'

// Role Definition ID for 'Storage File Data SMB Share Elevated Contributor'
var storageFileDataSmbShareElevatedContributorRoleId = subscriptionResourceId('Microsoft.Authorization/roleDefinitions', 'a7264617-510b-434b-a828-9731dc254ea7')

resource storageAccount 'Microsoft.Storage/storageAccounts@2022-09-01' = {
  name: storageAccountName
  location: location
  sku: {
    name: 'Premium_LRS' // Changed from Standard_LRS
  }
  kind: 'FileStorage' // Changed from StorageV2 for Premium Files
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
    shareQuota: 100 // Added shareQuota (in GiB), minimum for Premium is 100
  }
}

// Assign the Elevated Contributor role to the specified admin principal ID if provided
resource adminRoleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = if (!empty(adminPrincipalId)) {
  name: guid(resourceGroup().id, fileShare.id, adminPrincipalId, storageFileDataSmbShareElevatedContributorRoleId) // Unique name for the role assignment
  scope: fileShare // Scope the assignment to the file share
  properties: {
    roleDefinitionId: storageFileDataSmbShareElevatedContributorRoleId
    principalId: adminPrincipalId
    principalType: adminPrincipalType
  }
}

resource containerGroup 'Microsoft.ContainerInstance/containerGroups@2023-05-01' = {
  name: containerGroupName
  location: location
  properties: {
    ipAddress: {
      type: 'Public'
      ports: [
        {
          protocol: 'Udp'
          port: 26900
        }
        {
          protocol: 'Tcp'
          port: 26900
        }
        {
          protocol: 'Udp'
          port: 26901
        }
        {
          protocol: 'Udp'
          port: 26902
        }
        {
          protocol: 'Udp'
          port: 26903
        }
      ]
      dnsNameLabel: 'dns-${toLower(containerGroupName)}'
    }
    containers: [
      {
        name: containerImageName
        properties: {
          image: '${containerRegistryName}.azurecr.io/${containerImageName}:${containerImageTag}'
          resources: {
            requests: {
              cpu: 2
              memoryInGB: 4
            }
          }
          ports: [
            {
              protocol: 'Udp'
              port: 26900
            }
            {
              protocol: 'Tcp'
              port: 26900
            }
            {
              protocol: 'Udp'
              port: 26901
            }
            {
              protocol: 'Udp'
              port: 26902
            }
            {
              protocol: 'Udp'
              port: 26903
            }
          ]
          environmentVariables: [
            {
              name: 'SERVERNAME'
              value: serverName
            }
            {
              name: 'SERVERPASSWORD'
              secureValue: serverPassword
            }
          ]
          volumeMounts: [
            {
              name: '7dtddata'
              mountPath: '/data'
            }
          ]
        }
      }
    ]
    osType: 'Linux'
    imageRegistryCredentials: [
      {
        server: '${containerRegistryName}.azurecr.io'
        username: acrUsername
        password: acrPassword
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
    restartPolicy: 'OnFailure'
  }
}

output containerGroupNameOutput string = containerGroupName
output containerGroupIp string = containerGroup.properties.ipAddress.ip
output containerGroupFqdn string = containerGroup.properties.ipAddress.fqdn
