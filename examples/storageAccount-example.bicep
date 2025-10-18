// Example deployment of Azure Storage Account with Private Endpoints
// This example shows how to deploy the Storage Account module with all storage services and private endpoints

@description('Name of the Storage Account (must be globally unique, 3-24 characters, lowercase letters and numbers only)')
param storageAccountName string = 'st${uniqueString(resourceGroup().id)}'

@description('Location for all resources')
param location string = resourceGroup().location

@description('Name of the virtual network')
param vnetName string = 'vnet-storage-example'

@description('Address prefix for the virtual network')
param vnetAddressPrefix string = '10.0.0.0/16'

@description('Name of the subnet for private endpoints')
param subnetName string = 'subnet-private-endpoints'

@description('Address prefix for the subnet')
param subnetAddressPrefix string = '10.0.1.0/24'

@description('Tags to apply to all resources')
param tags object = {
  Environment: 'Production'
  Application: 'StorageAccount'
}

// Virtual Network
resource vnet 'Microsoft.Network/virtualNetworks@2023-11-01' = {
  name: vnetName
  location: location
  tags: tags
  properties: {
    addressSpace: {
      addressPrefixes: [
        vnetAddressPrefix
      ]
    }
    subnets: [
      {
        name: subnetName
        properties: {
          addressPrefix: subnetAddressPrefix
          privateEndpointNetworkPolicies: 'Disabled'
        }
      }
    ]
  }
}

// Private DNS Zones for Storage Account services
resource blobPrivateDnsZone 'Microsoft.Network/privateDnsZones@2020-06-01' = {
  name: 'privatelink.blob.${environment().suffixes.storage}'
  location: 'global'
  tags: tags
}

resource filePrivateDnsZone 'Microsoft.Network/privateDnsZones@2020-06-01' = {
  name: 'privatelink.file.${environment().suffixes.storage}'
  location: 'global'
  tags: tags
}

resource queuePrivateDnsZone 'Microsoft.Network/privateDnsZones@2020-06-01' = {
  name: 'privatelink.queue.${environment().suffixes.storage}'
  location: 'global'
  tags: tags
}

resource tablePrivateDnsZone 'Microsoft.Network/privateDnsZones@2020-06-01' = {
  name: 'privatelink.table.${environment().suffixes.storage}'
  location: 'global'
  tags: tags
}

// Link Private DNS Zones to Virtual Network
resource blobPrivateDnsZoneLink 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2020-06-01' = {
  parent: blobPrivateDnsZone
  name: '${vnetName}-blob-link'
  location: 'global'
  properties: {
    registrationEnabled: false
    virtualNetwork: {
      id: vnet.id
    }
  }
}

resource filePrivateDnsZoneLink 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2020-06-01' = {
  parent: filePrivateDnsZone
  name: '${vnetName}-file-link'
  location: 'global'
  properties: {
    registrationEnabled: false
    virtualNetwork: {
      id: vnet.id
    }
  }
}

resource queuePrivateDnsZoneLink 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2020-06-01' = {
  parent: queuePrivateDnsZone
  name: '${vnetName}-queue-link'
  location: 'global'
  properties: {
    registrationEnabled: false
    virtualNetwork: {
      id: vnet.id
    }
  }
}

resource tablePrivateDnsZoneLink 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2020-06-01' = {
  parent: tablePrivateDnsZone
  name: '${vnetName}-table-link'
  location: 'global'
  properties: {
    registrationEnabled: false
    virtualNetwork: {
      id: vnet.id
    }
  }
}

// Deploy Storage Account Module with Private Endpoints
module storageAccount '../modules/storageAccount.bicep' = {
  name: 'storageAccount-deployment'
  params: {
    storageAccountName: storageAccountName
    location: location
    skuName: 'Standard_LRS'
    kind: 'StorageV2'
    enableBlobService: true
    enableFileService: true
    enableQueueService: true
    enableTableService: true
    enablePrivateEndpoint: true
    subnetId: vnet.properties.subnets[0].id
    blobPrivateEndpointName: 'pe-${storageAccountName}-blob'
    filePrivateEndpointName: 'pe-${storageAccountName}-file'
    queuePrivateEndpointName: 'pe-${storageAccountName}-queue'
    tablePrivateEndpointName: 'pe-${storageAccountName}-table'
    blobPrivateDnsZoneId: blobPrivateDnsZone.id
    filePrivateDnsZoneId: filePrivateDnsZone.id
    queuePrivateDnsZoneId: queuePrivateDnsZone.id
    tablePrivateDnsZoneId: tablePrivateDnsZone.id
    tags: tags
  }
}

// Outputs
@description('The resource ID of the Storage Account')
output storageAccountId string = storageAccount.outputs.storageAccountId

@description('The name of the Storage Account')
output storageAccountName string = storageAccount.outputs.storageAccountName

@description('The primary endpoints of the Storage Account')
output primaryEndpoints object = storageAccount.outputs.primaryEndpoints

@description('The resource ID of the blob private endpoint')
output blobPrivateEndpointId string = storageAccount.outputs.blobPrivateEndpointId

@description('The resource ID of the file private endpoint')
output filePrivateEndpointId string = storageAccount.outputs.filePrivateEndpointId

@description('The resource ID of the queue private endpoint')
output queuePrivateEndpointId string = storageAccount.outputs.queuePrivateEndpointId

@description('The resource ID of the table private endpoint')
output tablePrivateEndpointId string = storageAccount.outputs.tablePrivateEndpointId
