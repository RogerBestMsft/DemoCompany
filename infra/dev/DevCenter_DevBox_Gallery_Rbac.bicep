//Assigns the Devcenter identity the permission to read secrets
param galleryName string
param principalId string

resource gallery 'Microsoft.Compute/galleries@2022-03-03' existing = {
  name: galleryName
}

var galleryContributor = subscriptionResourceId('Microsoft.Authorization/roleDefinitions', 'b24988ac-6180-42a0-ab88-20f7382dd24c')

resource rbacSecretUserSp 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  scope: gallery
  name: guid(gallery.id, principalId, galleryContributor)
  properties: {
    roleDefinitionId: galleryContributor
    principalType: 'ServicePrincipal'
    principalId: principalId
  }
}

//Assigns the Devcenter identity permission to deploy to the Environment Resource Group
