@minLength(2)
@description('The location to use for the deployment. defaults to Resource Groups location.')
param location string = resourceGroup().location

@minLength(2)
@description('The prefix for resource naming.')
param resource_prefix string = 'echo'

param devCenter_Name string = 'echodevcenter'

param project_Name string = 'TestProjectA'

param netConnectionName string = 'echo-dcon-eastus'

param devboxDefinitionName string = 'echodevcenter-win11-ssd_256gb'

@description('Provide the AzureAd UserId to assign project rbac for (get the current user with az ad signed-in-user show --query id)')
param devboxProjectUser string = 'c8307c6a-8539-4540-8e45-e8fa520fd93c'

@description('Provide the AzureAd UserId to assign project rbac for (get the current user with az ad signed-in-user show --query id)')
param devboxProjectAdmin string = 'c8307c6a-8539-4540-8e45-e8fa520fd93c'

resource devcenter_resource 'Microsoft.DevCenter/devcenters@2023-04-01' existing = {
  name: devCenter_Name  
}

resource devcenter_project_resource 'Microsoft.DevCenter/projects@2022-11-11-preview' = {
  name: project_Name
  location: location
  properties: {
    devCenterId: devcenter_resource.id
  }
}

var devCenterDevBoxUserRoleId = subscriptionResourceId('Microsoft.Authorization/roleDefinitions', '45d50f46-0b78-4001-a660-4198cbe8cd05')
resource projectUserRbac 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  scope: devcenter_project_resource
  name: guid(devcenter_project_resource.id, devboxProjectUser, devCenterDevBoxUserRoleId)
  properties: {
    roleDefinitionId: devCenterDevBoxUserRoleId
    principalType: 'User'
    principalId: devboxProjectUser
  }
}
output projectId string = devcenter_project_resource.id

var devCenterDevBoxAdminRoleId = subscriptionResourceId('Microsoft.Authorization/roleDefinitions', '331c37c6-af14-46d9-b9f4-e1909e1b95a0')
resource projectAdminRbac 'Microsoft.Authorization/roleAssignments@2022-04-01' = if(!empty(devboxProjectAdmin)) {
  scope: devcenter_project_resource
  name: guid(devcenter_project_resource.id, devboxProjectAdmin, devCenterDevBoxAdminRoleId)
  properties: {
    roleDefinitionId: devCenterDevBoxAdminRoleId
    principalType: 'User'
    principalId: devboxProjectAdmin
  }
}

module adenetModule 'Project_ADE_Net.bicep' = {
  name: 'ProjectADENetDeploy'
  params: {
    resource_prefix: resource_prefix    
  }
}

module envtypeModule 'Project_EnvironmentType.bicep' = {
  name: 'ProjectEnvTypeDeploy'
  params: {
    devcenterName: devCenter_Name
    projectName: project_Name
    environmentName: 'ProjectEnv'
  }
}

module poolModule 'Project_DevBox_Pool.bicep' = {
  name: 'ProjectPoolDeploy'
  params: {
    devcenterName: devCenter_Name
    poolName: 'basicPool'
    projectName: project_Name
    dbdefinitionName: devboxDefinitionName
    netconnectName: netConnectionName  
  }
}
