@description('Location for the Virtual Network. If none is provided, the resource group location is used.')
param location string = resourceGroup().location

@minLength(2)
@maxLength(64)
@description('The name of the Azure Virtual Network.')
param name string

@description('The resource ID of the DevCenter.')
param devCenterId string

@minLength(1)
param addressPrefixes array

@minLength(1)
@maxLength(80)
param subnetName string = 'default'
param subnetAddressPrefix string

param vnetIdToPeerTo string

@description('Tags to apply to the resources')
param tags object = {}

@allowed([ 'AzureADJoin', 'HybridAzureADJoin', 'None' ])
@description('Active Directory join type')
param domainJoinType string = 'AzureADJoin'

var devCenterName = empty(devCenterId) ? 'devCenterName' : last(split(devCenterId, '/'))
var devCenterGroup = empty(devCenterId) ? '' : first(split(last(split(replace(devCenterId, 'resourceGroups', 'resourcegroups'), '/resourcegroups/')), '/'))
var devCenterSub = empty(devCenterId) ? '' : first(split(last(split(devCenterId, '/subscriptions/')), '/'))

var networkConnectionName = name
var networkPeerAName = '${name}_peerA'
var networkPeerBName = '${name}_peerB'

resource vnet 'Microsoft.Network/virtualNetworks@2022-05-01' = {
  name: name
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: addressPrefixes
    }
    subnets: [
      {
        name: subnetName
        properties: {
          addressPrefix: subnetAddressPrefix
          privateEndpointNetworkPolicies: 'Disabled'
          privateLinkServiceNetworkPolicies: 'Enabled'
        }
      }
    ]
  }
  tags: tags
}

resource networkConnection 'Microsoft.DevCenter/networkConnections@2023-01-01-preview' = if (domainJoinType != 'None') {
  name: networkConnectionName
  location: location
  properties: {
    subnetId: '${vnet.id}/subnets/${subnetName}'
    networkingResourceGroupName: 'ni-${networkConnectionName}'
    domainJoinType: domainJoinType
  }
  tags: tags
}

// If a devcenter resource id was provided attach the nc to the devcenter
module networkAttach 'networkAttach.bicep' = if ((!empty(devCenterId)) && (domainJoinType != 'None')) {
  scope: resourceGroup(devCenterSub, devCenterGroup)
  name: '${networkConnectionName}-attach'
  params: {
    #disable-next-line BCP335
    name: networkConnectionName
    devCenterName: devCenterName
    #disable-next-line BCP334
    networkConnectionId: networkConnection.id
  }
}

resource peering 'Microsoft.Network/virtualNetworks/virtualNetworkPeerings@2023-02-01' = if (!empty(vnetIdToPeerTo)) {
  name: networkPeerAName
  parent: vnet
  properties: {
    allowForwardedTraffic: true
    allowGatewayTransit: false
    allowVirtualNetworkAccess: true
    doNotVerifyRemoteGateways: false
    remoteVirtualNetwork: {
      id: vnetIdToPeerTo
    }
    useRemoteGateways: false
  }
}


output id string = vnet.id
output subnet string = subnetName
output subnetId string = '${vnet.id}/subnets/${subnetName}'
output networkConnectionId string = networkConnection.id
output networkConnectionName string = networkConnection.name
