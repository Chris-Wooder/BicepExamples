<#
.SYNOPSIS
    Deploys the Azure Service Bus Namespace using the serviceBus-example.bicep template.

.DESCRIPTION
    This script deploys an Azure Service Bus Namespace with private endpoint, CMK encryption,
    and diagnostic settings to stream logs to an Event Hub.

.PARAMETER ResourceGroupName
    The name of the resource group where the Service Bus will be deployed.

.PARAMETER Location
    The Azure region for the deployment. Defaults to 'eastus'.

.PARAMETER ServiceBusName
    The name of the Service Bus Namespace. If not provided, a unique name will be generated.

.PARAMETER UserAssignedIdentityId
    The resource ID of the existing user-assigned managed identity.
    Example: /subscriptions/{sub-id}/resourceGroups/{rg-name}/providers/Microsoft.ManagedIdentity/userAssignedIdentities/{identity-name}

.PARAMETER KeyVaultId
    The resource ID of the existing Key Vault containing the CMK.
    Example: /subscriptions/{sub-id}/resourceGroups/{rg-name}/providers/Microsoft.KeyVault/vaults/{vault-name}

.PARAMETER KeyName
    The name of the key in Key Vault to use for CMK encryption.

.PARAMETER EventHubAuthorizationRuleId
    The resource ID of the Event Hub Authorization Rule for diagnostic logs.
    Example: /subscriptions/{sub-id}/resourceGroups/{rg-name}/providers/Microsoft.EventHub/namespaces/{namespace}/authorizationRules/{rule-name}

.PARAMETER EventHubName
    The name of the Event Hub for diagnostic logs.

.PARAMETER VnetName
    The name of the virtual network. Defaults to 'vnet-servicebus-example'.

.PARAMETER SubnetName
    The name of the subnet for private endpoints. Defaults to 'subnet-private-endpoints'.

.PARAMETER Tags
    A hashtable of tags to apply to all resources. Defaults to Environment=Production, Application=ServiceBus.

.EXAMPLE
    .\Deploy-ServiceBus.ps1 `
        -ResourceGroupName "rg-servicebus" `
        -Location "eastus" `
        -ServiceBusName "sb-myapp-prod" `
        -UserAssignedIdentityId "/subscriptions/xxx/resourceGroups/rg-identity/providers/Microsoft.ManagedIdentity/userAssignedIdentities/mi-servicebus" `
        -KeyVaultId "/subscriptions/xxx/resourceGroups/rg-security/providers/Microsoft.KeyVault/vaults/kv-cmk" `
        -KeyName "servicebus-cmk" `
        -EventHubAuthorizationRuleId "/subscriptions/yyy/resourceGroups/rg-logging/providers/Microsoft.EventHub/namespaces/eh-logs/authorizationRules/RootManageSharedAccessKey" `
        -EventHubName "servicebus-logs"

.NOTES
    Prerequisites:
    - Azure CLI installed and logged in (az login)
    - Bicep CLI installed
    - Appropriate permissions to deploy resources
    - The user-assigned managed identity must have 'Key Vault Crypto Service Encryption User' role on the Key Vault
    - The Key Vault must have a key created with the specified KeyName
#>

[CmdletBinding()]
param (
    [Parameter(Mandatory = $true)]
    [string]$ResourceGroupName,

    [Parameter(Mandatory = $false)]
    [string]$Location = "eastus",

    [Parameter(Mandatory = $false)]
    [string]$ServiceBusName,

    [Parameter(Mandatory = $true)]
    [string]$UserAssignedIdentityId,

    [Parameter(Mandatory = $true)]
    [string]$KeyVaultId,

    [Parameter(Mandatory = $true)]
    [string]$KeyName,

    [Parameter(Mandatory = $true)]
    [string]$EventHubAuthorizationRuleId,

    [Parameter(Mandatory = $true)]
    [string]$EventHubName,

    [Parameter(Mandatory = $false)]
    [string]$VnetName = "vnet-servicebus-example",

    [Parameter(Mandatory = $false)]
    [string]$SubnetName = "subnet-private-endpoints",

    [Parameter(Mandatory = $false)]
    [hashtable]$Tags = @{
        Environment = "Production"
        Application = "ServiceBus"
    }
)

# Set error action preference
$ErrorActionPreference = "Stop"

# Get the script directory
$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
$templatePath = Join-Path -Path $scriptPath -ChildPath "..\examples\serviceBus-example.bicep"

# Validate template exists
if (-not (Test-Path $templatePath)) {
    Write-Error "Template file not found at: $templatePath"
    exit 1
}

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Azure Service Bus Deployment Script" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Check if Azure CLI is installed
Write-Host "Checking Azure CLI installation..." -ForegroundColor Yellow
try {
    $azVersion = az version --output json | ConvertFrom-Json
    Write-Host "Azure CLI version: $($azVersion.'azure-cli')" -ForegroundColor Green
}
catch {
    Write-Error "Azure CLI is not installed or not in PATH. Please install Azure CLI first."
    exit 1
}

# Check if logged in
Write-Host "Checking Azure login status..." -ForegroundColor Yellow
try {
    $account = az account show --output json | ConvertFrom-Json
    Write-Host "Logged in as: $($account.user.name)" -ForegroundColor Green
    Write-Host "Subscription: $($account.name) ($($account.id))" -ForegroundColor Green
}
catch {
    Write-Error "Not logged in to Azure. Please run 'az login' first."
    exit 1
}

# Check/Create Resource Group
Write-Host ""
Write-Host "Checking resource group '$ResourceGroupName'..." -ForegroundColor Yellow
$rgExists = az group exists --name $ResourceGroupName
if ($rgExists -eq "false") {
    Write-Host "Creating resource group '$ResourceGroupName' in '$Location'..." -ForegroundColor Yellow
    az group create --name $ResourceGroupName --location $Location --output none
    Write-Host "Resource group created." -ForegroundColor Green
}
else {
    Write-Host "Resource group exists." -ForegroundColor Green
}

# Build deployment parameters
$deploymentParams = @{
    location                    = $Location
    vnetName                    = $VnetName
    subnetName                  = $SubnetName
    userAssignedIdentityId      = $UserAssignedIdentityId
    keyVaultId                  = $KeyVaultId
    keyName                     = $KeyName
    eventHubAuthorizationRuleId = $EventHubAuthorizationRuleId
    eventHubName                = $EventHubName
}

# Add optional parameters
if (-not [string]::IsNullOrEmpty($ServiceBusName)) {
    $deploymentParams.serviceBusName = $ServiceBusName
}

# Add tags to deployment parameters
$deploymentParams.tags = $Tags

# Create a temporary parameters file
$tempParamsFile = [System.IO.Path]::GetTempFileName()
$tempParamsFile = $tempParamsFile -replace '\.tmp$', '.json'

$paramsObject = @{
    '$schema'      = "https://schema.management.azure.com/schemas/2019-04-01/deploymentParameters.json#"
    contentVersion = "1.0.0.0"
    parameters     = @{}
}

foreach ($key in $deploymentParams.Keys) {
    $paramsObject.parameters[$key] = @{ value = $deploymentParams[$key] }
}

$paramsObject | ConvertTo-Json -Depth 10 | Out-File -FilePath $tempParamsFile -Encoding utf8

Write-Host ""
Write-Host "Starting deployment..." -ForegroundColor Yellow
Write-Host "Template: $templatePath" -ForegroundColor Gray
Write-Host "Resource Group: $ResourceGroupName" -ForegroundColor Gray
Write-Host "Location: $Location" -ForegroundColor Gray
Write-Host ""

try {
    # Deploy the template
    $deploymentName = "servicebus-deployment-$(Get-Date -Format 'yyyyMMddHHmmss')"
    
    $result = az deployment group create `
        --name $deploymentName `
        --resource-group $ResourceGroupName `
        --template-file $templatePath `
        --parameters "@$tempParamsFile" `
        --output json | ConvertFrom-Json

    if ($LASTEXITCODE -eq 0) {
        Write-Host ""
        Write-Host "========================================" -ForegroundColor Green
        Write-Host "Deployment Successful!" -ForegroundColor Green
        Write-Host "========================================" -ForegroundColor Green
        Write-Host ""
        Write-Host "Outputs:" -ForegroundColor Cyan
        Write-Host "  Service Bus Namespace ID: $($result.properties.outputs.serviceBusNamespaceId.value)" -ForegroundColor White
        Write-Host "  Service Bus Namespace Name: $($result.properties.outputs.serviceBusNamespaceName.value)" -ForegroundColor White
        Write-Host "  Service Bus Endpoint: $($result.properties.outputs.serviceBusEndpoint.value)" -ForegroundColor White
        Write-Host "  Private Endpoint ID: $($result.properties.outputs.privateEndpointId.value)" -ForegroundColor White
    }
    else {
        Write-Error "Deployment failed with exit code: $LASTEXITCODE"
        exit 1
    }
}
catch {
    Write-Error "Deployment failed: $_"
    exit 1
}
finally {
    # Clean up temp file
    if (Test-Path $tempParamsFile) {
        Remove-Item -Path $tempParamsFile -Force
    }
}

Write-Host ""
Write-Host "Deployment complete." -ForegroundColor Green
