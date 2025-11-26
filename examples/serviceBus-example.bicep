// Example deployment of Azure Service Bus Namespace with Private Endpoint, CMK, and Diagnostics
// This example shows how to deploy the Service Bus module with all required parameters

@description('Name of the Service Bus Namespace')
param serviceBusName string = 'sb-${uniqueString(resourceGroup().id)}'

@description('Location for all resources')
param location string = resourceGroup().location

@description('Name of the virtual network')
param vnetName string = 'vnet-servicebus-example'

@description('Address prefix for the virtual network')
param vnetAddressPrefix string = '10.0.0.0/16'

@description('Name of the subnet for private endpoints')
param subnetName string = 'subnet-private-endpoints'

@description('Address prefix for the subnet')
param subnetAddressPrefix string = '10.0.1.0/24'

@description('Name of the private endpoint')
param privateEndpointName string = 'pe-${serviceBusName}'

@description('Tags to apply to all resources')
param tags object = {
  Environment: 'Production'
  Application: 'ServiceBus'
}

// Existing resources parameters - these would come from other deployments/resource groups
@description('Resource ID of the existing user-assigned managed identity')
param userAssignedIdentityId string

@description('Resource ID of the existing Key Vault containing the CMK')
param keyVaultId string

@description('Name of the key in Key Vault to use for CMK encryption')
param keyName string

@description('Resource ID of the Event Hub Authorization Rule for diagnostic logs (in different subscription)')
param eventHubAuthorizationRuleId string

@description('Name of the Event Hub for diagnostic logs')
param eventHubName string

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

// Private DNS Zone for Service Bus
resource privateDnsZone 'Microsoft.Network/privateDnsZones@2020-06-01' = {
  name: 'privatelink.servicebus.windows.net'
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

// Deploy Service Bus Module
module serviceBus '../modules/serviceBus.bicep' = {
  name: 'serviceBus-deployment'
  params: {
    name: serviceBusName
    location: location
    sku: 'Premium'
    capacity: 1
    tags: tags
    subnetId: vnet.properties.subnets[0].id
    privateEndpointName: privateEndpointName
    privateDnsZoneId: privateDnsZone.id
    userAssignedIdentityId: userAssignedIdentityId
    keyVaultId: keyVaultId
    keyName: keyName
    eventHubAuthorizationRuleId: eventHubAuthorizationRuleId
    eventHubName: eventHubName
  }
}

// Outputs
@description('The resource ID of the Service Bus Namespace')
output serviceBusNamespaceId string = serviceBus.outputs.serviceBusNamespaceId

@description('The name of the Service Bus Namespace')
output serviceBusNamespaceName string = serviceBus.outputs.serviceBusNamespaceName

@description('The Service Bus Namespace endpoint')
output serviceBusEndpoint string = serviceBus.outputs.serviceBusEndpoint

@description('The resource ID of the private endpoint')
output privateEndpointId string = serviceBus.outputs.privateEndpointId
