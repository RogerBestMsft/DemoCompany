targetScope = 'managementGroup'

@description('Name of the thing')
param name string = 'VanArsdelLTD'

@description('Location of the thing')
param location string = 'eastus' // This needs to stay eastus2

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
