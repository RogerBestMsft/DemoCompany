@minLength(3)
@maxLength(20)
@description('Prefix used to name all resources')
param resource_prefix string

@description('DevCenter name')
param devcenterName string

var dcgallery_name = 'DCGallery'

resource dc 'Microsoft.DevCenter/devcenters@2022-11-11-preview' existing = {
  name: devcenterName
}

module galleryModule 'DevCenter_ComputeGallery.bicep' = {
  name: 'devCenterComputeGalleryDeploy'
  params: {
    resource_prefix: resource_prefix
    location: resourceGroup().location    
  }
}

module rbac 'DevCenter_DevBox_Gallery_Rbac.bicep' = {
  name: '${deployment().name}-gallery-managedId-rbac'
  params: {
    galleryName: galleryModule.outputs.gallery_name
    principalId: dc.identity.principalId
  }
  dependsOn: [
    galleryModule
  ]
}


resource dcgallery 'Microsoft.DevCenter/devcenters/galleries@2023-04-01' = {
  name: dcgallery_name
  parent: dc
  properties: {
    galleryResourceId: galleryModule.outputs.gallery_id    
  }
  dependsOn: [
    rbac
  ]
}

output name string = dcgallery.name
output id string = dcgallery.id
