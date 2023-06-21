// param projects_WebAppProject_name string = 'WebAppProject'
// param devcenters_TRDevCenter_externalid string = '/subscriptions/572b41e6-5c44-486a-84d2-01d6202774ac/resourceGroups/TreyResearch_Development/providers/Microsoft.DevCenter/devcenters/TRDevCenter'

// resource projects_WebAppProject_name_resource 'Microsoft.DevCenter/projects@2023-04-01' = {
//   name: projects_WebAppProject_name
//   location: 'eastus'
//   properties: {
//     devCenterId: devcenters_TRDevCenter_externalid
//     description: 'Project with Web App environs'
//     devCenterUri: 'https://ec509c4c-6b8f-4558-a7b7-030ff99b57e0-trdevcenter.devcenter.azure.com/'
//   }
// }

// resource projects_WebAppProject_name_BasicWebApp 'Microsoft.DevCenter/projects/environmentTypes@2023-04-01' = {
//   parent: projects_WebAppProject_name_resource
//   name: 'BasicWebApp'
//   identity: {
//     type: 'SystemAssigned'
//   }
//   properties: {
//     deploymentTargetId: '/subscriptions/572b41e6-5c44-486a-84d2-01d6202774ac'
//     status: 'Enabled'
//     creatorRoleAssignment: {
//       roles: {
//         '8e3af657-a8ff-443c-a75c-2fe8c4bcb635': {}
//       }
//     }
//   }
// }

// resource projects_WebAppProject_name_TestUserIdentity 'Microsoft.DevCenter/projects/environmentTypes@2023-04-01' = {
//   parent: projects_WebAppProject_name_resource
//   name: 'TestUserIdentity'
//   identity: {
//     type: 'UserAssigned'
//     userAssignedIdentities: {
//       '/subscriptions/572b41e6-5c44-486a-84d2-01d6202774ac/resourceGroups/TreyResearch_Users/providers/Microsoft.ManagedIdentity/userAssignedIdentities/rbest_UserManagedIdentity': {}
//     }
//   }
//   properties: {
//     deploymentTargetId: '/subscriptions/572b41e6-5c44-486a-84d2-01d6202774ac'
//     status: 'Enabled'
//     creatorRoleAssignment: {
//       roles: {
//         '8e3af657-a8ff-443c-a75c-2fe8c4bcb635': {}
//         'b86a8fe4-44ce-4948-aee5-eccb2c155cd7': {}
//       }
//     }
//   }
// }
param devcenterName string
param environmentName string = 'sandbox'
param projectName string = 'developers'
//param keyvaultName string 
//param catalogName string = 'devcatalog'
//param catalogRepoUri string = 'https://github.com/RBDDcet/DevCatalogs.git'
param adeProjectUser string = ''

// @secure()
// @description('A PAT token is required, even for public repos')
// param catalogRepoPat string

resource dc 'Microsoft.DevCenter/devcenters@2022-11-11-preview' existing = {
  name: devcenterName
}

resource project 'Microsoft.DevCenter/projects@2022-11-11-preview' existing = {
  name: projectName
}

resource env 'Microsoft.DevCenter/devcenters/environmentTypes@2022-11-11-preview' = {
  name: environmentName
  parent: dc
}

// param environmentTypes array = ['Dev', 'Test', 'Staging']
// resource envs 'Microsoft.DevCenter/devcenters/environmentTypes@2022-11-11-preview' = [for envType in environmentTypes :{
//   name: envType
//   parent: dc
// }] 

//param deploymentTargetId string = '${subscription().id}/devcenter-deploy-bucket'
param deploymentTargetId string = subscription().id

var rbacRoleId = {
  owner: '8e3af657-a8ff-443c-a75c-2fe8c4bcb635'
  contributor: 'b24988ac-6180-42a0-ab88-20f7382dd24c'
  deployenvuser: '18e40d4e-8d2e-438d-97e1-9528336e149c'
}
output dti string = deploymentTargetId

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

resource projectAssign 'Microsoft.DevCenter/projects/environmentTypes@2022-11-11-preview' =  {
    name: environmentName
    parent: project
    identity: {
      type: 'SystemAssigned'
    }
    properties: {
      creatorRoleAssignment: {
        roles : {
          '${rbacRoleId.contributor}': {}
        }
      }
      status: 'Enabled'
      deploymentTargetId: deploymentTargetId
    }
  }
  

var adeUserRoleId = subscriptionResourceId('Microsoft.Authorization/roleDefinitions', rbacRoleId.deployenvuser) 
resource projectUserRbac 'Microsoft.Authorization/roleAssignments@2022-04-01' = if(!empty(adeProjectUser)) {
  scope: project
  name: guid(project.id, adeUserRoleId, adeProjectUser)
  properties: {
    roleDefinitionId: adeUserRoleId
    principalType: 'User'
    principalId: adeProjectUser
  }
}
