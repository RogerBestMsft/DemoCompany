targetScope = 'tenant'

@description('Name of the thing')
param name string = 'VanArsdelLTD'

@description('Location of the thing')
param location string = 'eastus2' // This needs to stay eastus2

@description('The principal ids of users to assign the role of DevCenter Project Admin.  Users must either have DevCenter Project Admin or DevCenter Dev Box User role in order to create a Dev Box.')
param projectAdmins array = [
  'c8307c6a-8539-4540-8e45-e8fa520fd93c' // rbest
]

@description('The principal ids of users to assign the role of DevCenter Dev Box User.  Users must either have DevCenter Project Admin or DevCenter Dev Box User role in order to create a Dev Box.')
param devBoxUsers array = [
  'c8307c6a-8539-4540-8e45-e8fa520fd93c' // rbest
  '36d7224b-8dc1-4a01-89c3-358d8f0ac3eb' // ariabest
]

@description('The principal ids of users to assign the role of DevCenter Deployment Environments User.  Users must either have Deployment Environments User role in order to create a Environments.')
param environmentUsers array = [
  'c8307c6a-8539-4540-8e45-e8fa520fd93c' //rbest
  '36d7224b-8dc1-4a01-89c3-358d8f0ac3eb' //ariabest
]

// Podcast-CI
param ciPrincipalId string = 'de408100-4e1f-4508-ae24-799cb44bdb74'

@description('Github Uri')
param githubUri string = 'https://github.com/RBDDcet/DevCatalogs.git'

//@secure()
@description('[Environments] Personal Access Token from GitHub with the repo scope')
//#disable-next-line secure-parameter-default
param githubPat string = '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'

@description('Github Path')
param githubPath string = '/DevCenter/Catalogs'

@description('Primary subscription')
param primarySubscription string = '572b41e6-5c44-486a-84d2-01d6202774ac'

@description('Tags to apply to the resources')
param tags object = {}

@description('[Project] An object with property keys containing the Project name and values containing Subscription and Description properties. See bicep file for example.')
param projects array = [
  {
    name: 'PNL_Alpha_DEV'
    subscriptionId: '572b41e6-5c44-486a-84d2-01d6202774ac'
  }
  {
    name: 'PNL_Bravo_DEV'
    subscriptionId: '572b41e6-5c44-486a-84d2-01d6202774ac'
  }
  {
    name: 'PNL_Charlie_DEV'
    subcriptionId:'572b41e6-5c44-486a-84d2-01d6202774ac'
  }
]

@description('[Environments] An object with property keys containing the Environment Type name and values containing Subscription and Description properties. See bicep file for example.')
param environmentTypes object = {
  Dev: '572b41e6-5c44-486a-84d2-01d6202774ac' // Contoso-Inc Dev
  Test: '572b41e6-5c44-486a-84d2-01d6202774ac' // Contoso-Inc Test
  Prod: '572b41e6-5c44-486a-84d2-01d6202774ac' // Contoso-Inc Prod
}

// clean up the keyvault name an add a suffix to ensure it's unique
var keyVaultNameStart = replace(replace(replace(toLower(trim(name)), ' ', '-'), '_', '-'), '.', '-')
var keyVaultNameAlmost = length(keyVaultNameStart) <= 24 ? keyVaultNameStart : take(keyVaultNameStart, 24)
var keyVaultName = '${keyVaultNameAlmost}kvk'

var vnetNameStart = replace(toLower(trim(name)), ' ', '-')
var vnetName = '${vnetNameStart}-vnet'

var galleryName = '${keyVaultNameAlmost}gallery'

// ------------------
// Resource Groups
// ------------------

module primaryRG 'resourceGroup.bicep' = {
  scope: subscription(primarySubscription)
  name: '${name}RG'
  params: {
    #disable-next-line BCP334 BCP335
    name: '${name}RG'
    location: location
    tags: tags
  }
}

module secondRG 'resourceGroup.bicep' = {
  scope: subscription(projects[0].subscriptionId)
  name: '${projects[0].name}RG'
  params: {
    #disable-next-line BCP334 BCP335
    name: '${projects[0].name}RG'
    location: location
    tags: tags
  }
}


// module rgDeploy 'resourceGroup.bicep' = [for projectRG in projects: {
//   scope: subscription(projectRG.subscriptionId)
//   name: projectRG.name
//   params: {
//     #disable-next-line BCP334 BCP335
//     name: projectRG.name
//     location: location
//     tags: tags
//   }]

// resource group_dc 'Microsoft.Resources/resourceGroups@2022-09-01' = {
//   scope: subscription
//   name: name
//   location: location
//   tags: tags
// }

// resource project_network 'Microsoft.Resources/resourceGroups@2022-09-01' = {
//   name: '${name}-Network'
//   location: location
//   tags: tags
// }

// resource ade_network 'Microsoft.Resources/resourceGroups@2022-09-01' = {
//   name: '${name}-ADE-Network'
//   location: location
//   tags: tags
// }

// ------------------
// Dev Center
// ------------------

// module devCenter 'devcenter.bicep' = {
//   scope: subscription(primarySubscription)
//   name: 'devcenter'
//   params: {
//     #disable-next-line BCP334 BCP335
//     name: name
//     keyVaultName: keyVaultName
//     galleryName: galleryName
//     githubUri: githubUri
//     githubPath: githubPath
//     githubPat: githubPat
//     environmentTypes: environmentTypes
//     location: location
//     tags: tags
//   }
// }

// ------------------
// Projects
// ------------------

// module project_primary_app 'project.bicep' = {
//   scope: group_dc
//   name: 'project-primary-app'
//   params: {
//     devCenterName: devCenter.outputs.devCenterName
//     name: 'Primary-App'
//     description: '.NET 6 reference application shown at .NET Conf 2021 featuring ASP.NET Core, Blazor, .NET MAUI, Microservices, and more!'
//     environmentTypes: environmentTypes
//     location: location
//     ciPrincipalId: ciPrincipalId
//     projectAdmins: projectAdmins
//     devBoxUsers: devBoxUsers
//     environmentUsers: environmentUsers
//     tags: tags
//   }
// }


// module projectDeploy 'project.bicep' = [for project in items(projects): {
//   name: project.value
//   scope: subscription(envType.value)
//   params: {
//     principalId: ciPrincipalId
//     role: 'Reader'
//     principalType: 'ServicePrincipal'
//   }

// module project_fabrikam_app 'project.bicep' = {
//   scope: group_dc
//   name: 'project-fabrikam-app'
//   params: {
//     devCenterName: devCenter.outputs.devCenterName
//     name: 'Fabrikam-App'
//     environmentTypes: environmentTypes
//     location: location
//     ciPrincipalId: ciPrincipalId
//     projectAdmins: projectAdmins
//     devBoxUsers: devBoxUsers
//     environmentUsers: environmentUsers
//     tags: tags
//   }
// }

// module project_orchard_core 'project.bicep' = {
//   scope: group_dc
//   name: 'project-orchard-core'
//   params: {
//     devCenterName: devCenter.outputs.devCenterName
//     name: 'Orchard-Core'
//     environmentTypes: environmentTypes
//     location: location
//     ciPrincipalId: ciPrincipalId
//     projectAdmins: projectAdmins
//     devBoxUsers: devBoxUsers
//     environmentUsers: environmentUsers
//     tags: tags
//   }
// }

// ------------------
// Networks
// ------------------

// module network 'network.bicep' = {
//   scope: project_network
//   name: 'network-${location}'
//   params: {
//     #disable-next-line BCP334 BCP335
//     name: '${vnetName}-${location}' // eastus2
//     addressPrefixes: [ '10.4.0.0/16' ]
//     subnetAddressPrefix: '10.4.0.0/24' // 250 + 5 Azure reserved addresses
//     devCenterId: devCenter.outputs.devCenterId
//     location: location
//     vnetIdToPeerTo: network_ade.outputs.id
//     tags: tags
//   }
// }

// module network_firewall 'network.bicep' = {
//   scope: project_network
//   name: 'network-${location}-firewall'
//   params: {
//     #disable-next-line BCP334 BCP335
//     name: '${vnetName}-${location}-firewall' // eastus2-firewall
//     addressPrefixes: [ '10.5.0.0/16' ]
//     subnetAddressPrefix: '10.5.0.0/24' // 250 + 5 Azure reserved addresses
//     devCenterId: devCenter.outputs.devCenterId
//     location: location
//     vnetIdToPeerTo: network_ade.outputs.id
//     tags: tags
//   }
// }

// module network_ade 'network.bicep' = {
//   scope: ade_network
//   name: 'network-ade'
//   params: {
//     #disable-next-line BCP334 BCP335
//     name: '${vnetName}-${location}-ade'
//     addressPrefixes: [ '10.6.0.0/16' ]
//     subnetAddressPrefix: '10.6.0.0/24' // 250 + 5 Azure reserved addresses
//     #disable-next-line no-hardcoded-location
//     devCenterId: devCenter.outputs.devCenterId
//     domainJoinType: 'None'
//     location: location
//     vnetIdToPeerTo: ''
//     tags: tags
//   }
// }

// module network_westus3_paw 'network.bicep' = {
//   scope: project_network
//   name: 'network-westus3-paw'
//   params: {
//     #disable-next-line BCP334 BCP335
//     name: '${vnetName}-westus3-paw'
//     addressPrefixes: [ '10.7.0.0/16' ]
//     subnetAddressPrefix: '10.7.0.0/24' // 250 + 5 Azure reserved addresses
//     devCenterId: devCenter.outputs.devCenterId
//     #disable-next-line no-hardcoded-location
//     location: 'westus3'
//     tags: tags
//   }
// }

// module network_westeurope 'network.bicep' = {
//   scope: project_network
//   name: 'network-westeurope'
//   params: {
//     #disable-next-line BCP334 BCP335
//     name: '${vnetName}-westeurope'
//     addressPrefixes: [ '10.8.0.0/16' ]
//     subnetAddressPrefix: '10.8.0.0/24' // 250 + 5 Azure reserved addresses
//     devCenterId: devCenter.outputs.devCenterId
//     #disable-next-line no-hardcoded-location
//     location: 'westeurope'
//     tags: tags
//   }
// }

// ------------------
// DevBox Definitions
// ------------------

// module backend_dev_def 'devboxDefinition.bicep' = {
//   scope: group_dc
//   name: 'def-backend-dev'
//   params: {
//     name: 'Backend-Dev-Definition'
//     compute: '16c64gb'
//     storage: '256'
//     #disable-next-line BCP334 BCP335
//     devCenterName: devCenter.outputs.devCenterName
//     galleryName: 'default'
//     imageName: 'microsoftvisualstudio_visualstudioplustools_vs-2022-ent-general-win11-m365-gen2'
//     location: location
//     tags: tags
//   }
// }

// module frontend_dev_def 'devboxDefinition.bicep' = {
//   scope: group_dc
//   name: 'def-frontend-dev'
//   params: {
//     name: 'Frontend-Dev-Definition'
//     compute: '8c32gb'
//     storage: '512'
//     #disable-next-line BCP334 BCP335
//     devCenterName: devCenter.outputs.devCenterName
//     galleryName: 'default'
//     imageName: 'microsoftvisualstudio_visualstudioplustools_vs-2022-ent-general-win11-m365-gen2'
//     location: location
//     tags: tags
//   }
// }

// module dataeng_dev_def 'devboxDefinition.bicep' = {
//   scope: group_dc
//   name: 'def-data-eng'
//   params: {
//     name: 'DataEng-Dev-Definition'
//     compute: '8c32gb'
//     storage: '1024'
//     #disable-next-line BCP334 BCP335
//     devCenterName: devCenter.outputs.devCenterName
//     galleryName: 'default'
//     imageName: 'microsoftvisualstudio_visualstudioplustools_vs-2022-ent-general-win11-m365-gen2'
//     location: location
//     tags: tags
//   }
// }

// // ------------------
// // DevBox Pools
// // ------------------

module pool_backend_eastus2 'pool.bicep' = {
  scope: group_dc
  name: 'pool-backend-eastus2'
  params: {
    name: 'Backend-Dev-EastUS2'
    #disable-next-line BCP334 BCP335
    devBoxDefinitionName: backend_dev_def.outputs.definitionName
    #disable-next-line BCP334 BCP335
    networkConnectionName: network.outputs.networkConnectionName
    #disable-next-line BCP334 BCP335
    projectName: project_primary_app.outputs.projectName
    location: location
    tags: tags
  }
}

// module pool_backend_westus3 'pool.bicep' = {
//   scope: group_dc
//   name: 'pool-backend-westus3'
//   params: {
//     name: 'Backend-Dev-WestUS3'
//     #disable-next-line BCP334 BCP335
//     devBoxDefinitionName: backend_dev_def.outputs.definitionName
//     #disable-next-line BCP334 BCP335
//     networkConnectionName: network_westus3.outputs.networkConnectionName
//     #disable-next-line BCP334 BCP335
//     projectName: project_podcast_app.outputs.projectName
//     location: location
//     tags: tags
//   }
// }

// module pool_backend_westeurope 'pool.bicep' = {
//   scope: group_dc
//   name: 'pool-backend-westeurope'
//   params: {
//     name: 'Backend-Dev-WestEurope'
//     #disable-next-line BCP334 BCP335
//     devBoxDefinitionName: backend_dev_def.outputs.definitionName
//     #disable-next-line BCP334 BCP335
//     networkConnectionName: network_westeurope.outputs.networkConnectionName
//     #disable-next-line BCP334 BCP335
//     projectName: project_podcast_app.outputs.projectName
//     location: location
//     tags: tags
//   }
// }

// module pool_frontend_westus3 'pool.bicep' = {
//   scope: group_dc
//   name: 'pool-frontend-westus3'
//   params: {
//     name: 'Frontend-Dev-WestUS3'
//     #disable-next-line BCP334 BCP335
//     devBoxDefinitionName: frontend_dev_def.outputs.definitionName
//     #disable-next-line BCP334 BCP335
//     networkConnectionName: network_westus3.outputs.networkConnectionName
//     #disable-next-line BCP334 BCP335
//     projectName: project_podcast_app.outputs.projectName
//     location: location
//     tags: tags
//   }
// }

// module pool_dataeng_westus3 'pool.bicep' = {
//   scope: group_dc
//   name: 'pool-dataeng-westus3'
//   params: {
//     name: 'Data-Engineer-WestUS3'
//     #disable-next-line BCP334 BCP335
//     devBoxDefinitionName: dataeng_dev_def.outputs.definitionName
//     #disable-next-line BCP334 BCP335
//     networkConnectionName: network_westus3.outputs.networkConnectionName
//     #disable-next-line BCP334 BCP335
//     projectName: project_podcast_app.outputs.projectName
//     location: location
//     tags: tags
//   }
// }

// module pool_paw_westus3 'pool.bicep' = {
//   scope: group_dc
//   name: 'pool-paw-westus3'
//   params: {
//     name: 'PAW-WestUS3'
//     #disable-next-line BCP334 BCP335
//     devBoxDefinitionName: backend_dev_def.outputs.definitionName
//     #disable-next-line BCP334 BCP335
//     networkConnectionName: network_westus3_paw.outputs.networkConnectionName
//     #disable-next-line BCP334 BCP335
//     projectName: project_podcast_app.outputs.projectName
//     location: location
//     tags: tags
//   }
// }

// // Fabrikam-App
// module pool_backend_westus3_fa 'pool.bicep' = {
//   scope: group_dc
//   name: 'pool-backend-westus3-fa'
//   params: {
//     name: 'Backend-Dev-WestUS3'
//     #disable-next-line BCP334 BCP335
//     devBoxDefinitionName: backend_dev_def.outputs.definitionName
//     #disable-next-line BCP334 BCP335
//     networkConnectionName: network_westus3.outputs.networkConnectionName
//     #disable-next-line BCP334 BCP335
//     projectName: project_fabrikam_app.outputs.projectName
//     location: location
//     tags: tags
//   }
// }

// // Orchard-Core
// module pool_backend_westus3_oc 'pool.bicep' = {
//   scope: group_dc
//   name: 'pool-backend-westus3-oc'
//   params: {
//     name: 'Backend-Dev-WestUS3'
//     #disable-next-line BCP334 BCP335
//     devBoxDefinitionName: backend_dev_def.outputs.definitionName
//     #disable-next-line BCP334 BCP335
//     networkConnectionName: network_westus3.outputs.networkConnectionName
//     #disable-next-line BCP334 BCP335
//     projectName: project_orchard_core.outputs.projectName
//     location: location
//     tags: tags
//   }
// }

// ------------------
// Sub CI Roles
// ------------------

// CI identity must be assigned subscription reader role to all environment type subscriptions
// otherwise it has to log out and log in again to see the environment type subscriptions

module envReaderAssignmentIds 'subscriptionRoles.bicep' = [for envType in items(environmentTypes): {
  name: guid('reader${ciPrincipalId}${envType.key}')
  scope: subscription(envType.value)
  params: {
    principalId: ciPrincipalId
    role: 'Reader'
    principalType: 'ServicePrincipal'
  }
}]
