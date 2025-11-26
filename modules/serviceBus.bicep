// Azure Service Bus Namespace Module
// This module creates an Azure Service Bus Namespace with private endpoint support, CMK encryption, and diagnostic settings

@description('Name of the Service Bus Namespace')
param name string

@description('Location for the Service Bus Namespace')
param location string = resourceGroup().location

@description('SKU for the Service Bus Namespace')
@allowed([
  'Basic'
  'Standard'
  'Premium'
])
param sku string = 'Premium'

@description('Messaging units for Premium tier (1, 2, 4, 8, or 16). Only applicable for Premium SKU.')
@allowed([
  1
  2
  4
  8
  16
])
param capacity int = 1

@description('Tags to apply to resources')
param tags object = {}

// Private Endpoint Parameters
@description('Resource ID of the subnet for private endpoint')
param subnetId string

@description('Name of the private endpoint')
param privateEndpointName string

@description('Resource ID of the private DNS zone for Service Bus (optional)')
param privateDnsZoneId string = ''

// User-Assigned Managed Identity Parameters
@description('Resource ID of the user-assigned managed identity')
param userAssignedIdentityId string

// CMK Parameters
@description('Resource ID of the Key Vault containing the CMK')
param keyVaultId string

@description('Name of the key in Key Vault to use for CMK encryption')
param keyName string

@description('Version of the key to use (optional, leave empty to use latest)')
param keyVersion string = ''

// Diagnostic Settings Parameters
@description('Resource ID of the Event Hub Authorization Rule for diagnostic logs')
param eventHubAuthorizationRuleId string

@description('Name of the Event Hub for diagnostic logs')
param eventHubName string

// Derived values
var isPremium = sku == 'Premium'
var keyVaultName = last(split(keyVaultId, '/'))
var keyVaultUri = 'https://${keyVaultName}${environment().suffixes.keyvaultDns}/'

// Service Bus Namespace resource
resource serviceBusNamespace 'Microsoft.ServiceBus/namespaces@2022-10-01-preview' = {
  name: name
  location: location
  tags: tags
  sku: {
    name: sku
    tier: sku
    capacity: isPremium ? capacity : null
  }
  identity: {
    type: 'UserAssigned'
    userAssignedIdentities: {
      '${userAssignedIdentityId}': {}
    }
  }
  properties: {
    minimumTlsVersion: '1.2'
    publicNetworkAccess: 'Disabled'
    disableLocalAuth: false
    zoneRedundant: isPremium
    encryption: isPremium ? {
      keySource: 'Microsoft.KeyVault'
      keyVaultProperties: [
        {
          keyName: keyName
          keyVaultUri: keyVaultUri
          keyVersion: empty(keyVersion) ? null : keyVersion
          identity: {
            userAssignedIdentity: userAssignedIdentityId
          }
        }
      ]
      requireInfrastructureEncryption: true
    } : null
  }
}

// Private Endpoint
resource privateEndpoint 'Microsoft.Network/privateEndpoints@2023-11-01' = {
  name: privateEndpointName
  location: location
  tags: tags
  properties: {
    subnet: {
      id: subnetId
    }
    privateLinkServiceConnections: [
      {
        name: privateEndpointName
        properties: {
          privateLinkServiceId: serviceBusNamespace.id
          groupIds: [
            'namespace'
          ]
        }
      }
    ]
  }
}

// Private DNS Zone Group (optional, but recommended for proper DNS resolution)
resource privateDnsZoneGroup 'Microsoft.Network/privateEndpoints/privateDnsZoneGroups@2023-11-01' = if (!empty(privateDnsZoneId)) {
  parent: privateEndpoint
  name: 'default'
  properties: {
    privateDnsZoneConfigs: [
      {
        name: 'privatelink-servicebus-windows-net'
        properties: {
          privateDnsZoneId: privateDnsZoneId
        }
      }
    ]
  }
}

// Diagnostic Setting
resource diagnosticSetting 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = {
  name: '${name}-diagnostic'
  scope: serviceBusNamespace
  properties: {
    eventHubAuthorizationRuleId: eventHubAuthorizationRuleId
    eventHubName: eventHubName
    logs: [
      {
        categoryGroup: 'allLogs'
        enabled: true
      }
    ]
    metrics: [
      {
        category: 'AllMetrics'
        enabled: true
      }
    ]
  }
}

// Outputs
@description('The resource ID of the Service Bus Namespace')
output serviceBusNamespaceId string = serviceBusNamespace.id

@description('The name of the Service Bus Namespace')
output serviceBusNamespaceName string = serviceBusNamespace.name

@description('The Service Bus Namespace endpoint')
output serviceBusEndpoint string = serviceBusNamespace.properties.serviceBusEndpoint

@description('The resource ID of the private endpoint')
output privateEndpointId string = privateEndpoint.id

@description('The name of the private endpoint')
output privateEndpointName string = privateEndpoint.name
