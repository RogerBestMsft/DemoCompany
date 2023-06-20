@minLength(2)
@description('The location to use for the deployment. defaults to Resource Groups location.')
param location string = resourceGroup().location

@minLength(3)
@maxLength(20)
@description('Prefix used to name all resources')
param resource_prefix string

var devcenter_gallery_name_raw = '${resource_prefix}gallery${uniqueString(resourceGroup().id, resource_prefix)}'
var devcenter_gallery_name = length(devcenter_gallery_name_raw) > 24 ? substring(devcenter_gallery_name_raw, 0, 24) : devcenter_gallery_name_raw

resource devCenter_gallery_resource 'Microsoft.Compute/galleries@2022-03-03' = {
  name: devcenter_gallery_name
  location: location
  properties: {
    description: 'Custom gallery'
  }
}

output gallery_name string = devCenter_gallery_resource.name
output gallery_id string = devCenter_gallery_resource.id
