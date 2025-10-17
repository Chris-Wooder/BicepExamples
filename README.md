# BicepExamples

A collection of reusable Azure Bicep modules for common Azure resources.

## Modules

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

### Deploying the Example

1. Clone this repository
2. Navigate to the examples directory
3. Deploy using Azure CLI:

```bash
az deployment group create \
  --resource-group <your-resource-group> \
  --template-file examples/keyVault-example.bicep \
  --parameters keyVaultName=<unique-name>
```

### Validating Bicep Files

```bash
# Validate a specific module
bicep build modules/keyVault.bicep

# Validate an example
bicep build examples/keyVault-example.bicep
```

## Security Considerations

- The Key Vault module enforces **public network access disabled** by default
- **Soft delete** and **purge protection** are enabled by default to prevent accidental or malicious deletion
- Network access is restricted to **private endpoint only**
- Uses **Azure RBAC** for access control by default

## Contributing

Feel free to submit issues and enhancement requests!