targetScope = 'subscription'

@description('The identity principalId to assign Ownership role')
param principalId string

var ownerDefinitionId = subscriptionResourceId('Microsoft.Authorization/roleDefinitions', '8e3af657-a8ff-443c-a75c-2fe8c4bcb635')

resource ownerAssignmentId 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid('owner${subscription().subscriptionId}${principalId}')
  properties: {
    roleDefinitionId: ownerDefinitionId
    principalId: principalId
    principalType: 'ServicePrincipal'
  }
  scope: subscription()
}
