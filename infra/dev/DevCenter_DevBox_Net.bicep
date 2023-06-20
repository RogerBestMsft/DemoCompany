@minLength(2)
@description('The location to use for the deployment. defaults to Resource Groups location.')
param location string = resourceGroup().location

@minLength(3)
@maxLength(20)
@description('Prefix used to name all resources')
param resource_prefix string

@description('DevCenter Name')
param devcenterName string

param subnetName string = 'sn-devpools'
param vnetAddress string = '19.0.0.0/16'
param subnetAddress string = '19.0.0.0/24'

@description('The name of a new resource group that will be created to store some Networking resources (like NICs) in')
param networkingResourceGroupName string = '${resourceGroup().name}-networking-${location}'

resource dc 'Microsoft.DevCenter/devcenters@2022-11-11-preview' existing = {
  name: devcenterName
}

resource virtualNetwork 'Microsoft.Network/virtualNetworks@2022-07-01' = {
  name: '${resource_prefix}-vnet-${location}'
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: [
        vnetAddress
      ]
    }
    subnets: [
      {
        name: subnetName
        properties: {
          addressPrefix: subnetAddress
        }
      }
    ]
  }
}

resource networkconnection 'Microsoft.DevCenter/networkConnections@2022-11-11-preview' = {
  name: '${resource_prefix}-con-${location}'
  location: location
  properties: {
    domainJoinType: 'AzureADJoin'
    subnetId: '${virtualNetwork.id}/subnets/${subnetName}'
    networkingResourceGroupName: networkingResourceGroupName
  }
}

resource attachedNetwork 'Microsoft.DevCenter/devcenters/attachednetworks@2022-11-11-preview' = {
  name: '${resource_prefix}-dcon-${location}'
  parent: dc
  properties: {
    networkConnectionId: networkconnection.id
  }
}

output networkConnectionName string = networkconnection.name
output networkConnectionId string = networkconnection.id
output attachedNetworkName string = attachedNetwork.name
