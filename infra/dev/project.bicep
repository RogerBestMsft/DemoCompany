targetScope = 'resourceGroup'


@minLength(3)
@maxLength(26)
@sys.description('Name of the Project')
param name string
param description string = ''
param location string = resourceGroup().location
param devCenterId string
//param ciPrincipalId string
//param environmentTypes array = {}
@sys.description('Tags to apply to the resources')
param tags object = {}

//var contributorRoleId = 'b24988ac-6180-42a0-ab88-20f7382dd24c'

resource project 'Microsoft.DevCenter/projects@2023-01-01-preview' = {
  name: name
  location: location
  properties: {    
    devCenterId: devCenterId
    description: (!empty(description) ? description : null)
  }
  tags: tags
}

output projectName string = project.name
