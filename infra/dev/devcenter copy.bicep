@description('Location of the Dev Center. If none is provided, the resource group location is used.')
param location string = resourceGroup().location

@minLength(3)
@maxLength(26)
@description('Name of the Dev Center')
param name string

param keyVaultName string

param galleryName string

@description('Github uri')
param githubUri string

@secure()
@description('Personal Access Token from GitHub with the repo scope')
param githubPat string

@description('Github path')
param githubPath string

@description('Tags to apply to the resources')
param tags object = {}

param environmentTypes object = {}

// docs: https://docs.microsoft.com/en-us/azure/role-based-access-control/built-in-roles#key-vault-secrets-officer
var secretsAssignmentId = guid('kvsecretofficer${resourceGroup().id}${keyVaultName}${name}')
var secretsOfficerRoleResourceId = subscriptionResourceId('Microsoft.Authorization/roleDefinitions', 'b86a8fe4-44ce-4948-aee5-eccb2c155cd7')

var galleryAssignmentId = guid('gallerycont${resourceGroup().id}${galleryName}${name}')
var galleryContributor = subscriptionResourceId('Microsoft.Authorization/roleDefinitions', 'b24988ac-6180-42a0-ab88-20f7382dd24c')

resource devCenter 'Microsoft.DevCenter/devcenters@2023-01-01-preview' = {
  name: name
  location: location
  identity: {
    type: 'SystemAssigned'
  }
  tags: tags
}

// assign dev center identity owner role on subscription
module subscriptionAssignment 'subscriptionRoles.bicep' = {
  name: guid('owner${name}${subscription().subscriptionId}')
  scope: subscription()
  params: {
    principalId: devCenter.identity.principalId
    role: 'Owner'
    principalType: 'ServicePrincipal'
  }
}

// assign dev center identity owner role on each environment type subscription
module envSubscriptionsAssignment 'subscriptionRoles.bicep' = [for envType in items(environmentTypes): {
  name: guid('owner${name}${envType.key}')
  scope: subscription(envType.value)
  params: {
    principalId: devCenter.identity.principalId
    role: 'Owner'
    principalType: 'ServicePrincipal'
  }
}]

// create the catalog
resource catalog 'Microsoft.DevCenter/devcenters/catalogs@2023-01-01-preview' = {
  parent: devCenter
  name: 'Environments'
  properties: {
    gitHub: {
      uri: githubUri
      branch: 'main'
      path: githubPath
      secretIdentifier: githubPatSecret.properties.secretUri
    }
  }
}

// create the dev center level environment types
resource envTypes 'Microsoft.DevCenter/devcenters/environmentTypes@2023-01-01-preview' = [for envType in items(environmentTypes): {
  parent: devCenter
  name: envType.key
  properties: {}
}]

// ------------------
// Key Vault
// ------------------

// create a key vault
resource keyVault 'Microsoft.KeyVault/vaults@2022-07-01' = {
  name: keyVaultName
  location: location
  properties: {
    enabledForDeployment: true
    enabledForTemplateDeployment: true
    enabledForDiskEncryption: false
    tenantId: tenant().tenantId
    enableRbacAuthorization: true
    sku: {
      family: 'A'
      name: 'standard'
    }
  }
  tags: tags
}

// assign dev center identity secrets officer role on key vault
resource keyVaultAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: secretsAssignmentId
  properties: {
    principalId: devCenter.identity.principalId
    principalType: 'ServicePrincipal'
    roleDefinitionId: secretsOfficerRoleResourceId
  }
  scope: keyVault
}

// add the github pat token to the key vault
resource githubPatSecret 'Microsoft.KeyVault/vaults/secrets@2022-07-01' = {
  name: 'github-pat'
  parent: keyVault
  properties: {
    value: githubPat
    attributes: {
      enabled: true
    }
  }
  tags: tags
}

// ------------------
// Compute Gallery
// ------------------

// create a compute gallery
resource gallery 'Microsoft.Compute/galleries@2022-03-03' = {
  name: galleryName
  location: location
  properties: {
    description: 'Custom gallery'
  }
}

resource galleryAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  scope: gallery
  name: galleryAssignmentId
  properties: {
    roleDefinitionId: galleryContributor
    principalType: 'ServicePrincipal'
    principalId: devCenter.identity.principalId
  }
}

resource dcgallery 'Microsoft.DevCenter/devcenters/galleries@2023-04-01' = {
  name: name
  parent: devCenter
  properties: {
    galleryResourceId: gallery.id
  }
  dependsOn: [
    galleryAssignment
  ]
}

output devCenterId string = devCenter.id
output devCenterName string = devCenter.name
output devCenterIdentity string = devCenter.identity.principalId
