// Azure Storage Account Module
// This module creates an Azure Storage Account with optional private endpoint support for all storage services

@description('Name of the Storage Account (3-24 characters, lowercase letters and numbers only)')
@minLength(3)
@maxLength(24)
param storageAccountName string

@description('Location for the Storage Account')
param location string = resourceGroup().location

@description('SKU name for the Storage Account')
@allowed([
  'Standard_LRS'
  'Standard_GRS'
  'Standard_RAGRS'
  'Standard_ZRS'
  'Premium_LRS'
  'Premium_ZRS'
])
param skuName string = 'Standard_LRS'

@description('Storage Account kind')
@allowed([
  'Storage'
  'StorageV2'
  'BlobStorage'
  'FileStorage'
  'BlockBlobStorage'
])
param kind string = 'StorageV2'

@description('Enable blob service')
param enableBlobService bool = true

@description('Enable file service')
param enableFileService bool = true

@description('Enable queue service')
param enableQueueService bool = true

@description('Enable table service')
param enableTableService bool = true

@description('Enable private endpoint for storage account')
param enablePrivateEndpoint bool = false

@description('Resource ID of the subnet for private endpoint (required if enablePrivateEndpoint is true)')
param subnetId string = ''

@description('Name of the private endpoint for blob service')
param blobPrivateEndpointName string = ''

@description('Name of the private endpoint for file service')
param filePrivateEndpointName string = ''

@description('Name of the private endpoint for queue service')
param queuePrivateEndpointName string = ''

@description('Name of the private endpoint for table service')
param tablePrivateEndpointName string = ''

@description('Resource ID of the private DNS zone for blob storage (optional)')
param blobPrivateDnsZoneId string = ''

@description('Resource ID of the private DNS zone for file storage (optional)')
param filePrivateDnsZoneId string = ''

@description('Resource ID of the private DNS zone for queue storage (optional)')
param queuePrivateDnsZoneId string = ''

@description('Resource ID of the private DNS zone for table storage (optional)')
param tablePrivateDnsZoneId string = ''

@description('Tags to apply to resources')
param tags object = {}

@description('Enable HTTPS traffic only')
param supportsHttpsTrafficOnly bool = true

@description('Minimum TLS version')
@allowed([
  'TLS1_0'
  'TLS1_1'
  'TLS1_2'
])
param minimumTlsVersion string = 'TLS1_2'

@description('Allow or disallow public network access')
@allowed([
  'Enabled'
  'Disabled'
])
param publicNetworkAccess string = enablePrivateEndpoint ? 'Disabled' : 'Enabled'

// Storage Account resource
resource storageAccount 'Microsoft.Storage/storageAccounts@2023-05-01' = {
  name: storageAccountName
  location: location
  tags: tags
  sku: {
    name: skuName
  }
  kind: kind
  properties: {
    supportsHttpsTrafficOnly: supportsHttpsTrafficOnly
    minimumTlsVersion: minimumTlsVersion
    publicNetworkAccess: publicNetworkAccess
    networkAcls: enablePrivateEndpoint ? {
      bypass: 'AzureServices'
      defaultAction: 'Deny'
      ipRules: []
      virtualNetworkRules: []
    } : {
      bypass: 'AzureServices'
      defaultAction: 'Allow'
      ipRules: []
      virtualNetworkRules: []
    }
  }
}

// Blob Service
resource blobService 'Microsoft.Storage/storageAccounts/blobServices@2023-05-01' = if (enableBlobService) {
  parent: storageAccount
  name: 'default'
  properties: {}
}

// File Service
resource fileService 'Microsoft.Storage/storageAccounts/fileServices@2023-05-01' = if (enableFileService) {
  parent: storageAccount
  name: 'default'
  properties: {}
}

// Queue Service
resource queueService 'Microsoft.Storage/storageAccounts/queueServices@2023-05-01' = if (enableQueueService) {
  parent: storageAccount
  name: 'default'
  properties: {}
}

// Table Service
resource tableService 'Microsoft.Storage/storageAccounts/tableServices@2023-05-01' = if (enableTableService) {
  parent: storageAccount
  name: 'default'
  properties: {}
}

// Private Endpoint for Blob
resource blobPrivateEndpoint 'Microsoft.Network/privateEndpoints@2023-11-01' = if (enablePrivateEndpoint && enableBlobService && !empty(blobPrivateEndpointName)) {
  name: blobPrivateEndpointName
  location: location
  tags: tags
  properties: {
    subnet: {
      id: subnetId
    }
    privateLinkServiceConnections: [
      {
        name: blobPrivateEndpointName
        properties: {
          privateLinkServiceId: storageAccount.id
          groupIds: [
            'blob'
          ]
        }
      }
    ]
  }
}

// Private DNS Zone Group for Blob
resource blobPrivateDnsZoneGroup 'Microsoft.Network/privateEndpoints/privateDnsZoneGroups@2023-11-01' = if (enablePrivateEndpoint && enableBlobService && !empty(blobPrivateEndpointName) && !empty(blobPrivateDnsZoneId)) {
  parent: blobPrivateEndpoint
  name: 'default'
  properties: {
    privateDnsZoneConfigs: [
      {
        name: 'privatelink-blob-core-windows-net'
        properties: {
          privateDnsZoneId: blobPrivateDnsZoneId
        }
      }
    ]
  }
}

// Private Endpoint for File
resource filePrivateEndpoint 'Microsoft.Network/privateEndpoints@2023-11-01' = if (enablePrivateEndpoint && enableFileService && !empty(filePrivateEndpointName)) {
  name: filePrivateEndpointName
  location: location
  tags: tags
  properties: {
    subnet: {
      id: subnetId
    }
    privateLinkServiceConnections: [
      {
        name: filePrivateEndpointName
        properties: {
          privateLinkServiceId: storageAccount.id
          groupIds: [
            'file'
          ]
        }
      }
    ]
  }
}

// Private DNS Zone Group for File
resource filePrivateDnsZoneGroup 'Microsoft.Network/privateEndpoints/privateDnsZoneGroups@2023-11-01' = if (enablePrivateEndpoint && enableFileService && !empty(filePrivateEndpointName) && !empty(filePrivateDnsZoneId)) {
  parent: filePrivateEndpoint
  name: 'default'
  properties: {
    privateDnsZoneConfigs: [
      {
        name: 'privatelink-file-core-windows-net'
        properties: {
          privateDnsZoneId: filePrivateDnsZoneId
        }
      }
    ]
  }
}

// Private Endpoint for Queue
resource queuePrivateEndpoint 'Microsoft.Network/privateEndpoints@2023-11-01' = if (enablePrivateEndpoint && enableQueueService && !empty(queuePrivateEndpointName)) {
  name: queuePrivateEndpointName
  location: location
  tags: tags
  properties: {
    subnet: {
      id: subnetId
    }
    privateLinkServiceConnections: [
      {
        name: queuePrivateEndpointName
        properties: {
          privateLinkServiceId: storageAccount.id
          groupIds: [
            'queue'
          ]
        }
      }
    ]
  }
}

// Private DNS Zone Group for Queue
resource queuePrivateDnsZoneGroup 'Microsoft.Network/privateEndpoints/privateDnsZoneGroups@2023-11-01' = if (enablePrivateEndpoint && enableQueueService && !empty(queuePrivateEndpointName) && !empty(queuePrivateDnsZoneId)) {
  parent: queuePrivateEndpoint
  name: 'default'
  properties: {
    privateDnsZoneConfigs: [
      {
        name: 'privatelink-queue-core-windows-net'
        properties: {
          privateDnsZoneId: queuePrivateDnsZoneId
        }
      }
    ]
  }
}

// Private Endpoint for Table
resource tablePrivateEndpoint 'Microsoft.Network/privateEndpoints@2023-11-01' = if (enablePrivateEndpoint && enableTableService && !empty(tablePrivateEndpointName)) {
  name: tablePrivateEndpointName
  location: location
  tags: tags
  properties: {
    subnet: {
      id: subnetId
    }
    privateLinkServiceConnections: [
      {
        name: tablePrivateEndpointName
        properties: {
          privateLinkServiceId: storageAccount.id
          groupIds: [
            'table'
          ]
        }
      }
    ]
  }
}

// Private DNS Zone Group for Table
resource tablePrivateDnsZoneGroup 'Microsoft.Network/privateEndpoints/privateDnsZoneGroups@2023-11-01' = if (enablePrivateEndpoint && enableTableService && !empty(tablePrivateEndpointName) && !empty(tablePrivateDnsZoneId)) {
  parent: tablePrivateEndpoint
  name: 'default'
  properties: {
    privateDnsZoneConfigs: [
      {
        name: 'privatelink-table-core-windows-net'
        properties: {
          privateDnsZoneId: tablePrivateDnsZoneId
        }
      }
    ]
  }
}

// Outputs
@description('The resource ID of the Storage Account')
output storageAccountId string = storageAccount.id

@description('The name of the Storage Account')
output storageAccountName string = storageAccount.name

@description('The primary endpoints of the Storage Account')
output primaryEndpoints object = storageAccount.properties.primaryEndpoints

@description('The resource ID of the blob private endpoint')
output blobPrivateEndpointId string = enablePrivateEndpoint && enableBlobService && !empty(blobPrivateEndpointName) ? blobPrivateEndpoint.id : ''

@description('The resource ID of the file private endpoint')
output filePrivateEndpointId string = enablePrivateEndpoint && enableFileService && !empty(filePrivateEndpointName) ? filePrivateEndpoint.id : ''

@description('The resource ID of the queue private endpoint')
output queuePrivateEndpointId string = enablePrivateEndpoint && enableQueueService && !empty(queuePrivateEndpointName) ? queuePrivateEndpoint.id : ''

@description('The resource ID of the table private endpoint')
output tablePrivateEndpointId string = enablePrivateEndpoint && enableTableService && !empty(tablePrivateEndpointName) ? tablePrivateEndpoint.id : ''
