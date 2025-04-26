param location string = resourceGroup().location
param vmName string
param adminUsername string
@secure()
param adminPassword string

var addressPrefix = '10.0.0.0/24'
var nsgName = '${vmName}-nsg'
var vnetName = '${vmName}-vnet'
var pipName = '${vmName}-pip'
var nicName = '${vmName}-nic'

resource publicIP 'Microsoft.Network/publicIPAddresses@2023-05-01' = {
  name: pipName
  location: location
  sku: { name: 'Basic' }
  properties: { publicIPAllocationMethod: 'Dynamic' }
}

resource vnet 'Microsoft.Network/virtualNetworks@2023-05-01' = {
  name: vnetName
  location: location
  properties: {
    addressSpace: { addressPrefixes: [addressPrefix] }
    subnets: [
      { name: 'default', properties: { addressPrefix: addressPrefix } }
    ]
  }
}

resource nsg 'Microsoft.Network/networkSecurityGroups@2023-05-01' = {
  name: nsgName
  location: location
  properties: {
    securityRules: [
      { name: 'Allow-26900-TCP', properties: { priority: 1001, direction: 'Inbound', access: 'Allow', protocol: 'Tcp', sourcePortRange: '*', destinationPortRange: '26900', sourceAddressPrefix: '*', destinationAddressPrefix: '*' } }
      { name: 'Allow-26900-UDP', properties: { priority: 1002, direction: 'Inbound', access: 'Allow', protocol: 'Udp', sourcePortRange: '*', destinationPortRange: '26900', sourceAddressPrefix: '*', destinationAddressPrefix: '*' } }
      { name: 'Allow-26901-UDP', properties: { priority: 1003, direction: 'Inbound', access: 'Allow', protocol: 'Udp', sourcePortRange: '*', destinationPortRange: '26901', sourceAddressPrefix: '*', destinationAddressPrefix: '*' } }
      { name: 'Allow-26902-UDP', properties: { priority: 1004, direction: 'Inbound', access: 'Allow', protocol: 'Udp', sourcePortRange: '*', destinationPortRange: '26902', sourceAddressPrefix: '*', destinationAddressPrefix: '*' } }
      { name: 'Allow-26903-UDP', properties: { priority: 1005, direction: 'Inbound', access: 'Allow', protocol: 'Udp', sourcePortRange: '*', destinationPortRange: '26903', sourceAddressPrefix: '*', destinationAddressPrefix: '*' } }
      { name: 'Allow-8080-TCP', properties: { priority: 1006, direction: 'Inbound', access: 'Allow', protocol: 'Tcp', sourcePortRange: '*', destinationPortRange: '8080', sourceAddressPrefix: '*', destinationAddressPrefix: '*' } }
      { name: 'Allow-8081-TCP', properties: { priority: 1007, direction: 'Inbound', access: 'Allow', protocol: 'Tcp', sourcePortRange: '*', destinationPortRange: '8081', sourceAddressPrefix: '*', destinationAddressPrefix: '*' } }
      { name: 'Allow-22-TCP', properties: { priority: 1008, direction: 'Inbound', access: 'Allow', protocol: 'Tcp', sourcePortRange: '*', destinationPortRange: '22', sourceAddressPrefix: '*', destinationAddressPrefix: '*' } }
    ]
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
          subnet: { id: vnet.properties.subnets[0].id }
          privateIPAllocationMethod: 'Dynamic'
          publicIPAddress: { id: publicIP.id }
        }
      }
    ]
    networkSecurityGroup: { id: nsg.id }
  }
}

resource vm 'Microsoft.Compute/virtualMachines@2023-07-01' = {
  name: vmName
  location: location
  properties: {
    hardwareProfile: { vmSize: 'Standard_B2s' }
    osProfile: {
      computerName: vmName
      adminUsername: adminUsername
      adminPassword: adminPassword
      customData: base64(loadTextContent('../deployment/cloud-init.txt'))
    }
    storageProfile: {
      imageReference: {
        publisher: 'Canonical'
        offer: 'UbuntuServer'
        sku: '18.04-LTS'
        version: 'latest'
      }
      osDisk: { createOption: 'FromImage' }
    }
    networkProfile: { networkInterfaces: [ { id: nic.id } ] }
  }
}

output publicIp string = publicIP.properties.ipAddress
