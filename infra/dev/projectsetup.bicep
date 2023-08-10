targetScope = 'subscription'

param subscriptionId string

@sys.description('Location of the Project. If none is provided, the resource group location is used.')
param location string 

@minLength(3)
@maxLength(26)
@sys.description('Name of the Project')
param name string
param description string = ''
param resourceGroupName string

param devCenterSubId string
param devCenterRGName string
param devCenterName string

@sys.description('The principal ids of users to assign the role of DevCenter Project Admin.  Users must either have DevCenter Project Admin or DevCenter Dev Box User role in order to create a Dev Box.')
param projectAdmins array = [
  'c8307c6a-8539-4540-8e45-e8fa520fd93c'
 ]

@sys.description('The principal ids of users to assign the role of DevCenter Dev Box User.  Users must either have DevCenter Project Admin or DevCenter Dev Box User role in order to create a Dev Box.')
param devBoxUsers array = [
  'c8307c6a-8539-4540-8e45-e8fa520fd93c'
  '36d7224b-8dc1-4a01-89c3-358d8f0ac3eb'
]

@sys.description('The principal ids of users to assign the role of DevCenter Deployment Environments User.  Users must either have Deployment Environments User role in order to create a Environments.')
param environmentUsers array = [
  'c8307c6a-8539-4540-8e45-e8fa520fd93c'
  '36d7224b-8dc1-4a01-89c3-358d8f0ac3eb'
]

param ciPrincipalId string = ''

@sys.description('Tags to apply to the resources')
param tags object = {}

param environmentTypes array = [
  'Dev'
  'Test'
  'Production'
]

var readerRoleId = 'acdd72a7-3385-48ef-bd42-f606fba81ae7'
var contributorRoleId = 'b24988ac-6180-42a0-ab88-20f7382dd24c'

resource devCenter 'Microsoft.DevCenter/devcenters@2023-01-01-preview' existing = {
  name: devCenterName
  scope: resourceGroup(devCenterSubId, devCenterRGName)
}

module project_create 'project.bicep' = {
  scope: resourceGroup(subscriptionId,resourceGroupName)
  name: 'ProjectCreate'
  params: {
    name: name
    location: location
    description: description
    devCenterId: devCenter.id
    tags: tags
  }
}

// resource project 'Microsoft.DevCenter/projects@2023-01-01-preview' = {
//   name: name
//   location: location
//   properties: {    
//     devCenterId: devCenter.id
//     description: (!empty(description) ? description : null)
//   }
//   tags: tags
// }

module project_admins 'projectRoles.bicep' = [for user in projectAdmins: {
  scope: resourceGroup(subscriptionId,resourceGroupName)
  name: guid('admin', devCenter.id, name, user)
  params: {
    principalId: user
    projectName: name
    roles: [ 'ProjectAdmin' ]
  }
  dependsOn: [project_create]
}]

module devbox_users 'projectRoles.bicep' = [for user in devBoxUsers: {
  scope: resourceGroup(subscriptionId,resourceGroupName)
  name: guid('devbox', devCenter.id, name, user)
  params: {
    principalId: user
    projectName: name
    roles: [ 'DevBoxUser' ]
  }
  dependsOn: [project_create]
}]

module environment_users 'projectRoles.bicep' = [for user in environmentUsers: {
  scope: resourceGroup(subscriptionId,resourceGroupName)
  name: guid('ade', devCenter.id, name, user)
  params: {
    principalId: user
    projectName: name
    roles: [ 'EnvironmentsUser' ]
  }
  dependsOn: [project_create]
}]

// resource ci_reader_role 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
//   name: guid('reader', devCenterName, name, ciPrincipalId)
//   properties: {
//     principalId: ciPrincipalId
//     // Reader role
//     roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', readerRoleId)
//   }
// }

module projectEnvTypes 'projectEnvironmentType.bicep' = [for envType in environmentTypes: {
  scope: resourceGroup(subscriptionId,resourceGroupName)
  name: 'env-type-${name}-${envType}'
  params: {
    name: envType
    location: location
    projectName: name
    subscriptionId: subscriptionId
    devCenterId: devCenter.id
    ciPrincipalId: ciPrincipalId
    creatorRoleAssignment: contributorRoleId
    tags: tags
  }
  dependsOn: [project_create]
}]


