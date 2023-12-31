@minLength(3)
@maxLength(26)
@description('Name of the Dev Center')
param name string

@description('Location of the Dev Center.')
param location string

@description('Key vault Name')
param keyVaultName string

@description('Azure Compute Gallery Name')
param galleryName string

@description('Github uri')
param repoUri string

@secure()
@description('Personal Access Token from GitHub with the repo scope')
param repoAccess string

@description('Github path')
param repoPath string

@description('Organization vnet IP')
param vnet object = {
  name: 'VAGlobalNet'
  ipRange : [
    '20.0.0.0/16'
  ]
  subnets: [
    {
      name: 'default'
      iprange: '20.0.0.0/24'
    }
    {
      name: 'subconnect'
      iprange: '20.0.1.0/24'
    }
  ]
}

@description('Environment types available to projects.')
param environmentTypes array = [
  'Dev'
  'Test'
  'Production'
]


@description('Tags to apply to the resources')
param tags object = {}

var randomString = 'abcdefgh'

// docs: https://docs.microsoft.com/en-us/azure/role-based-access-control/built-in-roles#key-vault-secrets-officer
var secretsAssignmentId = guid('${randomString}${resourceGroup().id}${keyVaultName}${name}')
var secretsOfficerRoleResourceId = subscriptionResourceId('Microsoft.Authorization/roleDefinitions', 'b86a8fe4-44ce-4948-aee5-eccb2c155cd7')

var galleryAssignmentId = guid('${randomString}${resourceGroup().id}${galleryName}${name}')
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
  name: '${name}-SubscriptionAssignment'
  scope: subscription()
  params: {
    principalId: devCenter.identity.principalId
    role: 'Owner'
    principalType: 'ServicePrincipal'
  }
}

// assign dev center identity owner role on each environment type subscription
module envSubscriptionsAssignment 'subscriptionRoles.bicep' = [for envType in environmentTypes: {
  name: guid('owner${name}${envType}')
  scope: subscription()
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
      uri: repoUri
      branch: 'main'
      path: repoPath
      secretIdentifier: repoAccessSecret.properties.secretUri
    }
  }
}

// create the dev center level environment types
resource envTypes 'Microsoft.DevCenter/devcenters/environmentTypes@2023-01-01-preview' = [for envType in environmentTypes: {
  parent: devCenter
  name: envType
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
resource repoAccessSecret 'Microsoft.KeyVault/vaults/secrets@2022-07-01' = {
  name: 'github-pat'
  parent: keyVault
  properties: {
    value: repoAccess
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


// ------------------
// Organization Networking
// ------------------

resource organizationvnet 'Microsoft.Network/virtualNetworks@2022-05-01' = {
  name: vnet.name
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: vnet.ipRange
    }
    subnets: [for subnet in vnet.subnets: {
        name: subnet.name
        properties: {
          addressPrefix: subnet.ipRange
        }
      }
    ]
  }
  tags: tags
}


output devCenterId string = devCenter.id
output devCenterName string = devCenter.name
output devCenterIdentity string = devCenter.identity.principalId
//output envtype object = environmentTypes
output vnet object = vnet
