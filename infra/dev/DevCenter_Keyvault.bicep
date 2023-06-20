@minLength(2)
@description('The location to use for the deployment. defaults to Resource Groups location.')
param location string = resourceGroup().location

@minLength(3)
@maxLength(20)
@description('Prefix used to name all resources')
param resource_prefix string

@description('Enable support for private links')
param privateLinks bool = false

@description('If soft delete protection is enabled')
param keyVaultSoftDelete bool = true

@description('If purge protection is enabled')
param keyVaultPurgeProtection bool = true

@description('Add IP to KV firewall allow-list')
param keyVaultIPAllowlist array = []

param logAnalyticsWorkspaceId string = ''

var devcenter_keyvault_name_raw = '${resource_prefix}keyvault${uniqueString(resourceGroup().id, resource_prefix)}'
var devcenter_keyvault_name = length(devcenter_keyvault_name_raw) > 24 ? substring(devcenter_keyvault_name_raw, 0, 24) : devcenter_keyvault_name_raw
var devcenter_keyvault_diags_name = '${resource_prefix}keyvaultdiags'

var kvIPRules = [for kvIp in keyVaultIPAllowlist: {
  value: kvIp
}]

resource devcenter_keyvault_resource 'Microsoft.KeyVault/vaults@2021-11-01-preview' = {
  name: devcenter_keyvault_name
  location: location
  properties: {
    tenantId: subscription().tenantId
    sku: {
      family: 'A'
      name: 'standard'
    }
    // publicNetworkAccess:  whether the vault will accept traffic from public internet. If set to 'disabled' all traffic except private endpoint traffic and that that originates from trusted services will be blocked.
    publicNetworkAccess: privateLinks && empty(keyVaultIPAllowlist) ? 'disabled' : 'enabled'

    networkAcls: privateLinks && !empty(keyVaultIPAllowlist) ? {
      bypass: 'AzureServices'
      defaultAction: 'Deny'
      ipRules: kvIPRules
      virtualNetworkRules: []
    } : {}

    enableRbacAuthorization: true
    enabledForDeployment: false
    enabledForDiskEncryption: false
    enabledForTemplateDeployment: false
    enableSoftDelete: keyVaultSoftDelete
    enablePurgeProtection: keyVaultPurgeProtection ? true : json('null')
  }
}

resource devcenter_keyvault_diags_resource 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = if (!empty(logAnalyticsWorkspaceId)) {
  name: devcenter_keyvault_diags_name
  scope: devcenter_keyvault_resource
  properties: {
    workspaceId: logAnalyticsWorkspaceId
    logs: [
      {
        category: 'AuditEvent'
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

output keyVaultName string = devcenter_keyvault_resource.name
output keyVaultId string = devcenter_keyvault_resource.id
