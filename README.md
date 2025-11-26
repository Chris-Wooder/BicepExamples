# BicepExamples

A collection of reusable Azure Bicep modules for common Azure resources.

## Modules

### Azure Storage Account Module

A flexible Azure Storage Account module with optional private endpoint support for all storage services (blob, file, queue, table).

**Location:** `modules/storageAccount.bicep`

#### Features

- ✅ **All Storage Services:** Support for Blob, File, Queue, and Table storage services (all enabled by default)
- ✅ **Private Endpoints:** Optional private endpoint support for each storage service type
- ✅ **Network Security:** Optional public network access control with private endpoint isolation
- ✅ **Security Best Practices:** HTTPS-only traffic and TLS 1.2 minimum by default
- ✅ **Flexible Configuration:** Customizable SKU, kind, and service enablement
- ✅ **Multi-Cloud Support:** Uses environment() function for cloud compatibility

#### Parameters

| Parameter | Type | Required | Default | Description |
|-----------|------|----------|---------|-------------|
| `storageAccountName` | string | Yes | - | Name of the Storage Account (3-24 chars, lowercase and numbers) |
| `location` | string | No | `resourceGroup().location` | Location for the Storage Account |
| `skuName` | string | No | `Standard_LRS` | SKU name (Standard_LRS, Standard_GRS, etc.) |
| `kind` | string | No | `StorageV2` | Storage Account kind |
| `enableBlobService` | bool | No | `true` | Enable blob service |
| `enableFileService` | bool | No | `true` | Enable file service |
| `enableQueueService` | bool | No | `true` | Enable queue service |
| `enableTableService` | bool | No | `true` | Enable table service |
| `enablePrivateEndpoint` | bool | No | `false` | Enable private endpoints for storage account |
| `subnetId` | string | No | `''` | Resource ID of the subnet for private endpoints |
| `blobPrivateEndpointName` | string | No | `''` | Name of the private endpoint for blob service |
| `filePrivateEndpointName` | string | No | `''` | Name of the private endpoint for file service |
| `queuePrivateEndpointName` | string | No | `''` | Name of the private endpoint for queue service |
| `tablePrivateEndpointName` | string | No | `''` | Name of the private endpoint for table service |
| `blobPrivateDnsZoneId` | string | No | `''` | Resource ID of the private DNS zone for blob storage |
| `filePrivateDnsZoneId` | string | No | `''` | Resource ID of the private DNS zone for file storage |
| `queuePrivateDnsZoneId` | string | No | `''` | Resource ID of the private DNS zone for queue storage |
| `tablePrivateDnsZoneId` | string | No | `''` | Resource ID of the private DNS zone for table storage |
| `supportsHttpsTrafficOnly` | bool | No | `true` | Enable HTTPS traffic only |
| `minimumTlsVersion` | string | No | `TLS1_2` | Minimum TLS version |
| `publicNetworkAccess` | string | No | `Enabled` (or `Disabled` if private endpoint enabled) | Allow or disallow public network access |
| `tags` | object | No | `{}` | Tags to apply to resources |

#### Outputs

| Output | Type | Description |
|--------|------|-------------|
| `storageAccountId` | string | The resource ID of the Storage Account |
| `storageAccountName` | string | The name of the Storage Account |
| `primaryEndpoints` | object | The primary endpoints of the Storage Account |
| `blobPrivateEndpointId` | string | The resource ID of the blob private endpoint |
| `filePrivateEndpointId` | string | The resource ID of the file private endpoint |
| `queuePrivateEndpointId` | string | The resource ID of the queue private endpoint |
| `tablePrivateEndpointId` | string | The resource ID of the table private endpoint |

#### Usage Example

See `examples/storageAccount-example.bicep` for a complete deployment example that includes:
- Virtual Network with subnet configuration
- Private DNS Zones for all storage services
- Storage Account deployment with private endpoints for all services

**Basic usage (without private endpoints):**

```bicep
module storageAccount './modules/storageAccount.bicep' = {
  name: 'storageAccount-deployment'
  params: {
    storageAccountName: 'mystorageaccount'
    location: 'eastus'
    skuName: 'Standard_LRS'
    enableBlobService: true
    enableFileService: true
    enableQueueService: true
    enableTableService: true
  }
}
```

**With private endpoints:**

```bicep
module storageAccount './modules/storageAccount.bicep' = {
  name: 'storageAccount-deployment'
  params: {
    storageAccountName: 'mystorageaccount'
    location: 'eastus'
    skuName: 'Standard_LRS'
    enableBlobService: true
    enableFileService: true
    enableQueueService: true
    enableTableService: true
    enablePrivateEndpoint: true
    publicNetworkAccess: 'Disabled'  // Recommended when using private endpoints
    subnetId: '/subscriptions/.../subnets/my-subnet'
    blobPrivateEndpointName: 'pe-mystorageaccount-blob'
    filePrivateEndpointName: 'pe-mystorageaccount-file'
    queuePrivateEndpointName: 'pe-mystorageaccount-queue'
    tablePrivateEndpointName: 'pe-mystorageaccount-table'
    blobPrivateDnsZoneId: '/subscriptions/.../privateDnsZones/privatelink.blob.core.windows.net'
    filePrivateDnsZoneId: '/subscriptions/.../privateDnsZones/privatelink.file.core.windows.net'
    queuePrivateDnsZoneId: '/subscriptions/.../privateDnsZones/privatelink.queue.core.windows.net'
    tablePrivateDnsZoneId: '/subscriptions/.../privateDnsZones/privatelink.table.core.windows.net'
  }
}
```

**Selectively enable storage services:**

```bicep
module storageAccount './modules/storageAccount.bicep' = {
  name: 'storageAccount-deployment'
  params: {
    storageAccountName: 'mystorageaccount'
    location: 'eastus'
    skuName: 'Standard_LRS'
    enableBlobService: true
    enableFileService: false  // Disable file service
    enableQueueService: true
    enableTableService: false // Disable table service
  }
}
```

### Azure Service Bus Namespace Module

A secure Azure Service Bus Namespace module with private endpoint support, Customer-Managed Key (CMK) encryption, and diagnostic settings for log streaming.

**Location:** `modules/serviceBus.bicep`

#### Features

- ✅ **Private Endpoint:** Network isolation with private endpoint connectivity
- ✅ **CMK Encryption:** Customer-Managed Key encryption using Azure Key Vault (Premium SKU)
- ✅ **User-Assigned Identity:** Supports user-assigned managed identity for CMK access
- ✅ **Diagnostic Settings:** Stream all logs to Event Hub (supports cross-subscription)
- ✅ **Zone Redundancy:** Automatic zone redundancy for Premium tier
- ✅ **TLS 1.2:** Minimum TLS version 1.2 enforced
- ✅ **Network Security:** Public network access disabled by default
- ✅ **Flexible Configuration:** Customizable SKU, capacity, and tags

#### Parameters

| Parameter | Type | Required | Default | Description |
|-----------|------|----------|---------|-------------|
| `name` | string | Yes | - | Name of the Service Bus Namespace |
| `location` | string | No | `resourceGroup().location` | Location for the Service Bus Namespace |
| `sku` | string | No | `Premium` | SKU for the Service Bus (Basic, Standard, Premium) |
| `capacity` | int | No | `1` | Messaging units for Premium tier (1, 2, 4, 8, or 16) |
| `tags` | object | No | `{}` | Tags to apply to resources |
| `subnetId` | string | Yes | - | Resource ID of the subnet for private endpoint |
| `privateEndpointName` | string | Yes | - | Name of the private endpoint |
| `privateDnsZoneId` | string | No | `''` | Resource ID of the private DNS zone (optional) |
| `userAssignedIdentityId` | string | Yes | - | Resource ID of the user-assigned managed identity |
| `keyVaultId` | string | Yes | - | Resource ID of the Key Vault containing the CMK |
| `keyName` | string | Yes | - | Name of the key in Key Vault for CMK encryption |
| `keyVersion` | string | No | `''` | Version of the key (empty for latest) |
| `eventHubAuthorizationRuleId` | string | Yes | - | Resource ID of the Event Hub Authorization Rule |
| `eventHubName` | string | Yes | - | Name of the Event Hub for diagnostic logs |

#### Outputs

| Output | Type | Description |
|--------|------|-------------|
| `serviceBusNamespaceId` | string | The resource ID of the Service Bus Namespace |
| `serviceBusNamespaceName` | string | The name of the Service Bus Namespace |
| `serviceBusEndpoint` | string | The Service Bus Namespace endpoint |
| `privateEndpointId` | string | The resource ID of the private endpoint |
| `privateEndpointName` | string | The name of the private endpoint |

#### Prerequisites

Before deploying the Service Bus module, ensure the following resources exist:

1. **User-Assigned Managed Identity:** Create in a resource group and note the resource ID
2. **Key Vault with CMK Key:** 
   - The managed identity must have `Key Vault Crypto Service Encryption User` role on the Key Vault
   - A key must be created in the Key Vault for encryption
3. **Event Hub Namespace with Authorization Rule:** For diagnostic log streaming (can be in a different subscription)

#### Usage Example

See `examples/serviceBus-example.bicep` for a complete deployment example that includes:
- Virtual Network with subnet configuration
- Private DNS Zone setup
- Service Bus deployment with private endpoint, CMK, and diagnostics

**Basic usage:**

```bicep
module serviceBus './modules/serviceBus.bicep' = {
  name: 'serviceBus-deployment'
  params: {
    name: 'sb-myapp-prod'
    location: 'eastus'
    sku: 'Premium'
    capacity: 1
    subnetId: '/subscriptions/.../subnets/my-subnet'
    privateEndpointName: 'pe-sb-myapp-prod'
    privateDnsZoneId: '/subscriptions/.../privateDnsZones/privatelink.servicebus.windows.net'
    userAssignedIdentityId: '/subscriptions/.../userAssignedIdentities/mi-servicebus'
    keyVaultId: '/subscriptions/.../vaults/kv-cmk'
    keyName: 'servicebus-cmk'
    eventHubAuthorizationRuleId: '/subscriptions/.../authorizationRules/RootManageSharedAccessKey'
    eventHubName: 'servicebus-logs'
    tags: {
      Environment: 'Production'
      Application: 'ServiceBus'
    }
  }
}
```

#### PowerShell Deployment

A PowerShell deployment script is available at `scripts/Deploy-ServiceBus.ps1`:

```powershell
.\scripts\Deploy-ServiceBus.ps1 `
    -ResourceGroupName "rg-servicebus" `
    -Location "eastus" `
    -ServiceBusName "sb-myapp-prod" `
    -UserAssignedIdentityId "/subscriptions/xxx/resourceGroups/rg-identity/providers/Microsoft.ManagedIdentity/userAssignedIdentities/mi-servicebus" `
    -KeyVaultId "/subscriptions/xxx/resourceGroups/rg-security/providers/Microsoft.KeyVault/vaults/kv-cmk" `
    -KeyName "servicebus-cmk" `
    -EventHubAuthorizationRuleId "/subscriptions/yyy/resourceGroups/rg-logging/providers/Microsoft.EventHub/namespaces/eh-logs/authorizationRules/RootManageSharedAccessKey" `
    -EventHubName "servicebus-logs"
```

---

### Azure Key Vault Module

A secure Azure Key Vault module with private endpoint support, soft delete, and purge protection enabled.

**Location:** `modules/keyVault.bicep`

#### Features

- ✅ **Private Endpoint:** Network isolation with private endpoint connectivity
- ✅ **Soft Delete:** Enabled by default with configurable retention period (7-90 days, default: 90 days)
- ✅ **Purge Protection:** Enabled by default to prevent accidental or malicious deletion
- ✅ **RBAC Authorization:** Azure RBAC-based access control enabled by default
- ✅ **Network Security:** Public network access disabled, only private endpoint access allowed
- ✅ **Flexible Configuration:** Customizable parameters for various deployment scenarios

#### Parameters

| Parameter | Type | Required | Default | Description |
|-----------|------|----------|---------|-------------|
| `keyVaultName` | string | Yes | - | Name of the Key Vault |
| `location` | string | No | `resourceGroup().location` | Location for the Key Vault |
| `skuName` | string | No | `standard` | SKU name (standard or premium) |
| `tenantId` | string | No | `subscription().tenantId` | Tenant ID for the Key Vault |
| `enableSoftDelete` | bool | No | `true` | Enable soft delete for the Key Vault |
| `softDeleteRetentionInDays` | int | No | `90` | Soft delete retention period (7-90 days) |
| `enablePurgeProtection` | bool | No | `true` | Enable purge protection for the Key Vault |
| `enableRbacAuthorization` | bool | No | `true` | Enable RBAC authorization |
| `subnetId` | string | Yes | - | Resource ID of the subnet for private endpoint |
| `privateEndpointName` | string | Yes | - | Name of the private endpoint |
| `privateDnsZoneId` | string | No | `''` | Resource ID of the private DNS zone (optional) |
| `tags` | object | No | `{}` | Tags to apply to resources |

#### Outputs

| Output | Type | Description |
|--------|------|-------------|
| `keyVaultId` | string | The resource ID of the Key Vault |
| `keyVaultName` | string | The name of the Key Vault |
| `keyVaultUri` | string | The URI of the Key Vault |
| `privateEndpointId` | string | The resource ID of the private endpoint |
| `privateEndpointName` | string | The name of the private endpoint |

#### Usage Example

See `examples/keyVault-example.bicep` for a complete deployment example that includes:
- Virtual Network with subnet configuration
- Private DNS Zone setup
- Key Vault deployment with private endpoint

**Basic usage:**

```bicep
module keyVault './modules/keyVault.bicep' = {
  name: 'keyVault-deployment'
  params: {
    keyVaultName: 'my-keyvault'
    location: 'eastus'
    subnetId: '/subscriptions/.../subnets/my-subnet'
    privateEndpointName: 'pe-my-keyvault'
  }
}
```

**With private DNS zone:**

```bicep
module keyVault './modules/keyVault.bicep' = {
  name: 'keyVault-deployment'
  params: {
    keyVaultName: 'my-keyvault'
    location: 'eastus'
    subnetId: '/subscriptions/.../subnets/my-subnet'
    privateEndpointName: 'pe-my-keyvault'
    privateDnsZoneId: '/subscriptions/.../privateDnsZones/privatelink.vaultcore.azure.net'
    enableSoftDelete: true
    softDeleteRetentionInDays: 90
    enablePurgeProtection: true
  }
}
```

## Getting Started

### Prerequisites

- [Azure CLI](https://docs.microsoft.com/cli/azure/install-azure-cli)
- [Bicep CLI](https://docs.microsoft.com/azure/azure-resource-manager/bicep/install)

### Deploying the Examples

1. Clone this repository
2. Navigate to the examples directory
3. Deploy using Azure CLI:

**Key Vault Example:**
```bash
az deployment group create \
  --resource-group <your-resource-group> \
  --template-file examples/keyVault-example.bicep \
  --parameters keyVaultName=<unique-name>
```

**Storage Account Example:**
```bash
az deployment group create \
  --resource-group <your-resource-group> \
  --template-file examples/storageAccount-example.bicep \
  --parameters storageAccountName=<unique-name>
```

**Service Bus Example:**
```bash
az deployment group create \
  --resource-group <your-resource-group> \
  --template-file examples/serviceBus-example.bicep \
  --parameters serviceBusName=<unique-name> \
               userAssignedIdentityId=<identity-resource-id> \
               keyVaultId=<keyvault-resource-id> \
               keyName=<key-name> \
               eventHubAuthorizationRuleId=<eventhub-auth-rule-id> \
               eventHubName=<eventhub-name>
```

### Validating Bicep Files

```bash
# Validate the Key Vault module
bicep build modules/keyVault.bicep

# Validate the Key Vault example
bicep build examples/keyVault-example.bicep

# Validate the Storage Account module
bicep build modules/storageAccount.bicep

# Validate the Storage Account example
bicep build examples/storageAccount-example.bicep

# Validate the Service Bus module
bicep build modules/serviceBus.bicep

# Validate the Service Bus example
bicep build examples/serviceBus-example.bicep
```

## Security Considerations

### Service Bus Module
- **Public network access disabled** by default for network isolation
- **Customer-Managed Key (CMK) encryption** for data at rest (Premium SKU required)
- **User-Assigned Managed Identity** for secure key access
- **Minimum TLS version 1.2** enforced
- Network access is restricted to **private endpoint only**
- **Zone redundancy** enabled for Premium tier
- **Infrastructure encryption** enabled with CMK
- Diagnostic logs streamed to Event Hub for security monitoring

### Key Vault Module
- The Key Vault module enforces **public network access disabled** by default
- **Soft delete** and **purge protection** are enabled by default to prevent accidental or malicious deletion
- Network access is restricted to **private endpoint only**
- Uses **Azure RBAC** for access control by default

### Storage Account Module
- **HTTPS-only traffic** is enforced by default
- **Minimum TLS version 1.2** is required by default
- Optional **private endpoint support** for network isolation of all storage services
- When private endpoints are enabled, **public network access is automatically disabled**
- Network ACLs configured to deny by default when using private endpoints

## Contributing

Feel free to submit issues and enhancement requests!