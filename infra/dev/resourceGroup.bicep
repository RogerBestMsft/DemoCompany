targetScope = 'subscription'

@maxLength(63)
@description('Name of the Resource Group.')
param name string

@description('Location of the Resource Group.')
param location string

@description('Tags to apply to the resources')
param tags object = {}

resource RGroupCreate 'Microsoft.Resources/resourceGroups@2022-09-01' = {
  name: name
  location: location
  tags: tags
}

output resourceGroupName string = RGroupCreate.name
