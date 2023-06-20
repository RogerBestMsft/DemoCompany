
@minLength(2)
@description('Name of the key vault. (From DevCenter_Keyvault.bicep)')
param keyVaultName string

@minLength(2)
@description('The secret name to be added to the key vault.')
param secretName string

@secure()
@minLength(2)
@description('The secret value to be added.')
param secretValue string

resource devcenter_keyvault_resource 'Microsoft.KeyVault/vaults@2022-07-01' existing = {
  name: keyVaultName
}

resource kvSecret 'Microsoft.KeyVault/vaults/secrets@2022-07-01' = {
  name: secretName
  parent: devcenter_keyvault_resource
  properties: {
    value: secretValue
  }
}

output secretUri string =  kvSecret.properties.secretUri
