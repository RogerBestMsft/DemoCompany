// param projects_AllImageProject_name string = 'AllImageProject'

// resource projects_AllImageProject_name_DockerDesktopPool 'Microsoft.DevCenter/projects/pools@2023-04-01' = {
//   name: '${projects_AllImageProject_name}/DockerDesktopPool'
//   location: 'eastus'
//   properties: {
//     devBoxDefinitionName: 'DockerDesktop'
//     networkConnectionName: 'AdatumCorpNetworkConnector'
//     licenseType: 'Windows_Client'
//     localAdministrator: 'Enabled'
//   }
// }

// resource projects_AllImageProject_name_DockerDesktopPool_default 'Microsoft.DevCenter/projects/pools/schedules@2023-04-01' = {
//   parent: projects_AllImageProject_name_DockerDesktopPool
//   name: 'default'
//   properties: {
//     type: 'StopDevBox'
//     frequency: 'Daily'
//     time: '19:00'
//     timeZone: 'America/Los_Angeles'
//     state: 'Enabled'
//   }
// }

param devcenterName string
param poolName string = 'basicPool'
param projectName string
param location string = resourceGroup().location
param dbdefinitionName string 
param netconnectName string

resource dc 'Microsoft.DevCenter/devcenters@2022-11-11-preview' existing = {
  name: devcenterName
}

resource project 'Microsoft.DevCenter/projects@2022-11-11-preview' existing = {
  name: projectName
}

resource devboxpooldef 'Microsoft.DevCenter/projects/pools@2023-04-01' = {
  name: poolName
  parent: project
  location: location
  properties: {
    devBoxDefinitionName: dbdefinitionName
    networkConnectionName: netconnectName
    licenseType: 'Windows_Client'
    localAdministrator: 'Enabled'
  }
}

resource devboxpoolschedule 'Microsoft.DevCenter/projects/pools/schedules@2023-04-01' = {
  name: 'default'
  parent: devboxpooldef
  properties: {
    type: 'StopDevBox'
    frequency: 'Daily'
    time: '19:00'
    timeZone: 'America/Los_Angeles'
    state: 'Enabled'
  }
}
