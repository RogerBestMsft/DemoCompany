// param devCenter_subscription_id string = '572b41e6-5c44-486a-84d2-01d6202774ac'
// param tenant_id string = 'ec509c4c-6b8f-4558-a7b7-030ff99b57e0'
@minLength(2)
@description('The prefix for resource naming.')
param resource_prefix string = 'alpha'

// param resourceGroup_name string = 'Alpha_DC'
@minLength(2)
@description('The location to use for the deployment. defaults to Resource Groups location.')
param location string = resourceGroup().location

@minLength(2)
@description('The token secret for Catalog repo access.')
param repo_access_token string = ''

@description('Provide the AzureAd UserId to assign project rbac for (get the current user with az ad signed-in-user show --query id)')
param devboxProjectUser string 

@description('Provide the AzureAd UserId to assign project rbac for (get the current user with az ad signed-in-user show --query id)')
param devboxProjectAdmin string = ''

var devCenter_name = '${resource_prefix}devcenter'
var devCenter_project_alpha_name = '${resource_prefix}devcenter-project-alpha'
var devCenter_project_bravo_name = '${resource_prefix}devcenter-project-bravo'

resource devcenter_resource 'Microsoft.DevCenter/devcenters@2023-04-01' = {
  name: devCenter_name
  location: location
  identity: {
    type: 'SystemAssigned'
  }
}

// Project Alpha
resource devcenter_project_alpha_resource 'Microsoft.DevCenter/projects@2022-11-11-preview' = {
  name: devCenter_project_alpha_name
  location: location
  properties: {
    devCenterId: devcenter_resource.id
  }
}

var devCenterDevBoxUserRoleId = subscriptionResourceId('Microsoft.Authorization/roleDefinitions', '45d50f46-0b78-4001-a660-4198cbe8cd05')
resource projectAlphaUserRbac 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  scope: devcenter_project_alpha_resource
  name: guid(devcenter_project_alpha_resource.id, devboxProjectUser, devCenterDevBoxUserRoleId)
  properties: {
    roleDefinitionId: devCenterDevBoxUserRoleId
    principalType: 'User'
    principalId: devboxProjectUser
  }
}

var devCenterDevBoxAdminRoleId = subscriptionResourceId('Microsoft.Authorization/roleDefinitions', '331c37c6-af14-46d9-b9f4-e1909e1b95a0')
resource projectAlphaAdminRbac 'Microsoft.Authorization/roleAssignments@2022-04-01' = if(!empty(devboxProjectAdmin)) {
  scope: devcenter_project_alpha_resource
  name: guid(devcenter_project_alpha_resource.id, devboxProjectAdmin, devCenterDevBoxAdminRoleId)
  properties: {
    roleDefinitionId: devCenterDevBoxAdminRoleId
    principalType: 'User'
    principalId: devboxProjectAdmin
  }
}

// Project Bravo
resource devcenter_project_bravo_resource 'Microsoft.DevCenter/projects@2022-11-11-preview' = {
  name: devCenter_project_bravo_name
  location: location
  properties: {
    devCenterId: devcenter_resource.id
  }
}

resource projectBravoUserRbac 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  scope: devcenter_project_bravo_resource
  name: guid(devcenter_project_bravo_resource.id, devboxProjectUser, devCenterDevBoxUserRoleId)
  properties: {
    roleDefinitionId: devCenterDevBoxUserRoleId
    principalType: 'User'
    principalId: devboxProjectUser
  }
}

resource projectBravoAdminRbac 'Microsoft.Authorization/roleAssignments@2022-04-01' = if(!empty(devboxProjectAdmin)) {
  scope: devcenter_project_bravo_resource
  name: guid(devcenter_project_bravo_resource.id, devboxProjectAdmin, devCenterDevBoxAdminRoleId)
  properties: {
    roleDefinitionId: devCenterDevBoxAdminRoleId
    principalType: 'User'
    principalId: devboxProjectAdmin
  }
}


// param projects array = ['alpha', 'bravo', 'charlie']
// module projs 'Project/Project.bicep' = [for project in projects :{
//   name: project
//   params: {
//     devCenter_Name: devcenter_resource.name
//     project_Name: project
//     devboxProjectUser: devboxProjectUser
//     devboxProjectAdmin: devboxProjectAdmin
//   }
// }] 

module galleryModule 'DevCenter_DevBox_Gallery.bicep' = {
  name: 'devCenterGalleryDeploy'
  params: {
    resource_prefix: resource_prefix
    devcenterName: devcenter_resource.name    
  }
}

module kvModule 'DevCenter_Keyvault.bicep' = {
  name: 'devCenterKeyvaultDeploy'
  params: {
    resource_prefix: resource_prefix
    keyVaultIPAllowlist: []
  }
}

module catalogModule 'DevCenter_Catalog.bicep' = {
  name: 'devCenterCatalogDeploy'
  params: {
    keyvaultName: kvModule.outputs.keyVaultName
    devcenterName: devcenter_resource.name
    catalogRepoUri: 'https://github.com/RBDDcet/DevCatalogs.git'
    adeProjectUser: ''
    catalogRepoPat: repo_access_token
    projectTeamName: devcenter_project_alpha_resource.name
  }
}

module dbnetModule 'DevCenter_DevBox_Net.bicep' = {
  name: 'devCenterDevBoxNetDeploy'
  params: {
    resource_prefix: resource_prefix
    devcenterName: devcenter_resource.name
  }
}

module dbdefModule 'DevCenter_DevBox_Definition.bicep' = {
  name: 'devCenterDevBoxDefinitionDeploy'
  params: {
    devcenterName: devcenter_resource.name
    galleryName: galleryModule.outputs.name
  }
}

module appconfigModule 'DevCenter_AppConfiguration.bicep' = {
  name: 'devCenterAppConfigurationDeploy'
  params: {
    resource_prefix: resource_prefix
  }
}
