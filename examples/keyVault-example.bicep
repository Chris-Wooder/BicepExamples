// Example deployment of Azure Key Vault with Private Endpoint
// This example shows how to deploy the Key Vault module with all required parameters

@description('Name of the Key Vault (must be globally unique)')
param keyVaultName string = 'kv-${uniqueString(resourceGroup().id)}'

@description('Location for all resources')
param location string = resourceGroup().location

@description('Name of the virtual network')
param vnetName string = 'vnet-keyvault-example'

@description('Address prefix for the virtual network')
param vnetAddressPrefix string = '10.0.0.0/16'

@description('Name of the subnet for private endpoint')
param subnetName string = 'subnet-private-endpoints'

@description('Address prefix for the subnet')
param subnetAddressPrefix string = '10.0.1.0/24'

@description('Name of the private endpoint')
param privateEndpointName string = 'pe-${keyVaultName}'

@description('Tags to apply to all resources')
param tags object = {
  Environment: 'Production'
  Application: 'KeyVault'
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

// Private DNS Zone for Key Vault
resource privateDnsZone 'Microsoft.Network/privateDnsZones@2020-06-01' = {
  name: 'privatelink.vaultcore.azure.net'
  location: 'global'
  tags: tags
}

// Link Private DNS Zone to Virtual Network
resource privateDnsZoneLink 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2020-06-01' = {
  parent: privateDnsZone
  name: '${vnetName}-link'
  location: 'global'
  properties: {
    registrationEnabled: false
    virtualNetwork: {
      id: vnet.id
    }
  }
}

// Deploy Key Vault Module
module keyVault '../modules/keyVault.bicep' = {
  name: 'keyVault-deployment'
  params: {
    keyVaultName: keyVaultName
    location: location
    skuName: 'standard'
    enableSoftDelete: true
    softDeleteRetentionInDays: 90
    enablePurgeProtection: true
    enableRbacAuthorization: true
    subnetId: vnet.properties.subnets[0].id
    privateEndpointName: privateEndpointName
    privateDnsZoneId: privateDnsZone.id
    tags: tags
  }
}

// Outputs
@description('The resource ID of the Key Vault')
output keyVaultId string = keyVault.outputs.keyVaultId

@description('The name of the Key Vault')
output keyVaultName string = keyVault.outputs.keyVaultName

@description('The URI of the Key Vault')
output keyVaultUri string = keyVault.outputs.keyVaultUri

@description('The resource ID of the private endpoint')
output privateEndpointId string = keyVault.outputs.privateEndpointId
