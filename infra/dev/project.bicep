@sys.description('Location of the Project. If none is provided, the resource group location is used.')
param location string = resourceGroup().location

@minLength(3)
@maxLength(26)
@sys.description('Name of the Project')
param name string
param description string = ''

param devCenterName string

@sys.description('The principal ids of users to assign the role of DevCenter Project Admin.  Users must either have DevCenter Project Admin or DevCenter Dev Box User role in order to create a Dev Box.')
param projectAdmins array

@sys.description('The principal ids of users to assign the role of DevCenter Dev Box User.  Users must either have DevCenter Project Admin or DevCenter Dev Box User role in order to create a Dev Box.')
param devBoxUsers array

@sys.description('The principal ids of users to assign the role of DevCenter Deployment Environments User.  Users must either have Deployment Environments User role in order to create a Environments.')
param environmentUsers array

param ciPrincipalId string

@sys.description('Tags to apply to the resources')
param tags object = {}

param environmentTypes object = {}

var readerRoleId = 'acdd72a7-3385-48ef-bd42-f606fba81ae7'
var contributorRoleId = 'b24988ac-6180-42a0-ab88-20f7382dd24c'

resource devCenter 'Microsoft.DevCenter/devcenters@2023-01-01-preview' existing = {
  name: devCenterName
}

resource project 'Microsoft.DevCenter/projects@2023-01-01-preview' = {
  name: name
  location: location
  properties: {
    devCenterId: devCenter.id
    description: (!empty(description) ? description : null)
  }
  tags: tags
}

module project_admins 'projectRoles.bicep' = [for user in projectAdmins: {
  name: guid('admin', devCenterName, name, user)
  params: {
    principalId: user
    projectName: project.name
    roles: [ 'ProjectAdmin' ]
  }
}]

module devbox_users 'projectRoles.bicep' = [for user in devBoxUsers: {
  name: guid('devbox', devCenterName, name, user)
  params: {
    principalId: user
    projectName: project.name
    roles: [ 'DevBoxUser' ]
  }
}]

module environment_users 'projectRoles.bicep' = [for user in environmentUsers: {
  name: guid('ade', devCenterName, name, user)
  params: {
    principalId: user
    projectName: project.name
    roles: [ 'EnvironmentsUser' ]
  }
}]

// resource ci_reader_role 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
//   name: guid('reader', devCenterName, name, ciPrincipalId)
//   properties: {
//     principalId: ciPrincipalId
//     // Reader role
//     roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', readerRoleId)
//   }
// }

module projectEnvTypes 'projectEnvironmentType.bicep' = [for envType in items(environmentTypes): {
  name: 'env-type-${name}-${envType.key}'
  params: {
    name: envType.key
    location: location
    projectName: project.name
    subscriptionId: envType.value
    devCenterName: devCenterName
    ciPrincipalId: ciPrincipalId
    creatorRoleAssignment: contributorRoleId
    tags: tags
  }
}]

output projectName string = project.name
