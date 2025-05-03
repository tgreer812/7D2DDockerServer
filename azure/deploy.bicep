param location string = resourceGroup().location
param vmName string
param adminUsername string
@secure()
param adminPassword string
param customDataBase64 string
param customScriptCommand string // New parameter for the command

var nsgName = '${vmName}-nsg'
var vnetName = '${vmName}-vnet'
var subnetName = 'default'
var publicIpName = '${vmName}-pip'
var nicName = '${vmName}-nic'
var vmSize = 'Standard_B2s'
var osDiskCreateOption = 'FromImage'
var ubuntuImage = {
  publisher: 'canonical' // Match case from working VM JSON
  offer: 'ubuntu-24_04-lts' // Match offer from working VM JSON
  sku: 'server' // Match sku from working VM JSON
  version: 'latest'
}

resource publicIP 'Microsoft.Network/publicIPAddresses@2023-05-01' = {
  name: publicIpName
  location: location
  sku: { name: 'Standard' } // Standard SKU recommended
  properties: { publicIPAllocationMethod: 'Static' } // Static IP is useful for servers
}

resource nsg 'Microsoft.Network/networkSecurityGroups@2023-05-01' = {
  name: nsgName
  location: location
  properties: {
    securityRules: [
      {
        name: 'SSH'
        properties: {
          priority: 1000
          access: 'Allow'
          direction: 'Inbound'
          protocol: 'Tcp'
          sourcePortRange: '*'
          destinationPortRange: '22'
          sourceAddressPrefix: '*' // Consider restricting this to your IP for security
          destinationAddressPrefix: '*'
        }
      }
      {
        name: '7DTD_Game_UDP'
        properties: {
          priority: 1010
          access: 'Allow'
          direction: 'Inbound'
          protocol: 'Udp'
          sourcePortRange: '*'
          destinationPortRanges: [ '26900', '26901', '26902', '26903' ]
          sourceAddressPrefix: '*'
          destinationAddressPrefix: '*'
        }
      }
      {
        name: '7DTD_Game_TCP'
        properties: {
          priority: 1011
          access: 'Allow'
          direction: 'Inbound'
          protocol: 'Tcp'
          sourcePortRange: '*'
          destinationPortRange: '26900'
          sourceAddressPrefix: '*'
          destinationAddressPrefix: '*'
        }
      }
      {
        name: '7DTD_WebDashboard'
        properties: {
          priority: 1020
          access: 'Allow'
          direction: 'Inbound'
          protocol: 'Tcp'
          sourcePortRange: '*'
          destinationPortRange: '8080'
          sourceAddressPrefix: '*'
          destinationAddressPrefix: '*'
        }
      }
      {
        name: '7DTD_Telnet'
        properties: {
          priority: 1021
          access: 'Allow'
          direction: 'Inbound'
          protocol: 'Tcp'
          sourcePortRange: '*'
          destinationPortRange: '8081'
          sourceAddressPrefix: '*'
          destinationAddressPrefix: '*'
        }
      }
    ]
  }
}

resource vnet 'Microsoft.Network/virtualNetworks@2023-05-01' = {
  name: vnetName
  location: location
  properties: {
    addressSpace: { addressPrefixes: [ '10.0.0.0/16' ] }
    subnets: [ { name: subnetName, properties: { addressPrefix: '10.0.0.0/24', networkSecurityGroup: { id: nsg.id } } } ]
  }
}

resource nic 'Microsoft.Network/networkInterfaces@2023-05-01' = {
  name: nicName
  location: location
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfig1'
        properties: {
          subnet: { id: resourceId('Microsoft.Network/virtualNetworks/subnets', vnetName, subnetName) }
          privateIPAllocationMethod: 'Dynamic'
          publicIPAddress: { id: publicIP.id }
        }
      }
    ]
    networkSecurityGroup: { id: nsg.id } // Associate NSG directly with NIC
  }
  dependsOn: [ vnet ]
}

resource vm 'Microsoft.Compute/virtualMachines@2023-07-01' = {
  name: vmName
  location: location
  properties: {
    hardwareProfile: { vmSize: vmSize }
    osProfile: {
      computerName: vmName
      adminUsername: adminUsername
      adminPassword: adminPassword
      customData: customDataBase64
    }
    storageProfile: {
      imageReference: ubuntuImage
      osDisk: { 
        createOption: osDiskCreateOption
        // Consider adding disk size if default is too small
        // diskSizeGB: 128 
      }
    }
    networkProfile: { networkInterfaces: [ { id: nic.id } ] }
  }
}

resource vmCustomScriptExtension 'Microsoft.Compute/virtualMachines/extensions@2023-07-01' = {
  parent: vm // Associate with the VM
  name: 'install7dtdService'
  location: location
  properties: {
    publisher: 'Microsoft.Azure.Extensions'
    type: 'CustomScript'
    typeHandlerVersion: '2.1'
    autoUpgradeMinorVersion: true
    settings: {
      commandToExecute: customScriptCommand
    }
  }
}

output publicIp string = publicIP.properties.ipAddress
