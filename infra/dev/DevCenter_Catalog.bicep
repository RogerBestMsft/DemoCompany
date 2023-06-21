param devcenterName string
//param environmentName string = 'sandbox'
//param projectTeamName string = 'developers'
param keyvaultName string 
param catalogName string = 'devcatalog'
param catalogRepoUri string = 'https://github.com/RBDDcet/DevCatalogs.git'
//param adeProjectUser string = ''

@secure()
@description('A PAT token is required, even for public repos')
param catalogRepoPat string

resource dc 'Microsoft.DevCenter/devcenters@2022-11-11-preview' existing = {
  name: devcenterName
}

// resource project 'Microsoft.DevCenter/projects@2022-11-11-preview' existing = {
//   name: projectTeamName
// }

@description('A keyvault is required to store your pat token for the Catalog')
resource kv 'Microsoft.KeyVault/vaults@2023-02-01' existing = {
  name: keyvaultName
}

@description('Keyvault secrect holds pat token')
module kvSecret 'devCenter_Keyvault_secret.bicep' = if(!empty(catalogRepoPat)) {
  name: '${deployment().name}-keyvault-patSecret'
  params: {
    keyVaultName: kv.name
    secretName: catalogName
    secretValue: catalogRepoPat
  }
}

module rbac 'DevCenter_DevBox_KeyVault_Rbac.bicep' = {
  name: '${deployment().name}-keyvault-managedId-rbac'
  params: {
    keyVaultName: kv.name
    principalId: dc.identity.principalId
  }
}

// resource env 'Microsoft.DevCenter/devcenters/environmentTypes@2022-11-11-preview' = {
//   name: environmentName
//   parent: dc
// }

resource catalog 'Microsoft.DevCenter/devcenters/catalogs@2022-11-11-preview' = {
  name: catalogName
  parent: dc
  properties: {
    gitHub: {
      uri: catalogRepoUri
      branch: 'main'
      secretIdentifier: !empty(catalogRepoPat) ? kvSecret.outputs.secretUri : null
      path: '/DevCenter/Catalogs'
    }
  }
}

// param environmentTypes array = ['Dev', 'Test', 'Staging']
// resource envs 'Microsoft.DevCenter/devcenters/environmentTypes@2022-11-11-preview' = [for envType in environmentTypes :{
//   name: envType
//   parent: dc
// }] 

//param deploymentTargetId string = '${subscription().id}/devcenter-deploy-bucket'
// param deploymentTargetId string = subscription().id

// var rbacRoleId = {
//   owner: '8e3af657-a8ff-443c-a75c-2fe8c4bcb635'
//   contributor: 'b24988ac-6180-42a0-ab88-20f7382dd24c'
//   deployenvuser: '18e40d4e-8d2e-438d-97e1-9528336e149c'
// }
// output dti string = deploymentTargetId

// resource projectAssign 'Microsoft.DevCenter/projects/environmentTypes@2022-11-11-preview' =  [for envType in environmentTypes : {
//   name: envType
//   parent: project
//   identity: {
//     type: 'SystemAssigned'
//   }
//   properties: {
//     creatorRoleAssignment: {
//       roles : {
//         '${rbacRoleId.contributor}': {}
//       }
//     }
//     status: 'Enabled'
//     deploymentTargetId: deploymentTargetId
//   }
// }]

// var adeUserRoleId = subscriptionResourceId('Microsoft.Authorization/roleDefinitions', rbacRoleId.deployenvuser) 
// resource projectUserRbac 'Microsoft.Authorization/roleAssignments@2022-04-01' = if(!empty(adeProjectUser)) {
//   scope: project
//   name: guid(project.id, adeUserRoleId, adeProjectUser)
//   properties: {
//     roleDefinitionId: adeUserRoleId
//     principalType: 'User'
//     principalId: adeProjectUser
//   }
// }
