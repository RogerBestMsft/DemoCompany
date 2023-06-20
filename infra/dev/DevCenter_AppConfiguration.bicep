@minLength(3)
@maxLength(20)
@description('Prefix used to name all resources')
param resource_prefix string

@description('Specifies the Azure location where the app configuration store should be created.')
param location string = resourceGroup().location

var devcenter_appconfig_name_raw = '${resource_prefix}appconfig${uniqueString(resourceGroup().id, resource_prefix)}'
var devcenter_appconfig_name = length(devcenter_appconfig_name_raw) > 24 ? substring(devcenter_appconfig_name_raw, 0, 24) : devcenter_appconfig_name_raw


// @description('Specifies the names of the key-value resources. The name is a combination of key and label with $ as delimiter. The label is optional.')
// param keyValueNames array = [
//   'myKey'
//   'myKey$myLabel'
// ]

// @description('Specifies the values of the key-value resources. It\'s optional')
// param keyValueValues array = [
//   'Key-value without label'
//   'Key-value with label'
// ]

// @description('Specifies the content type of the key-value resources. For feature flag, the value should be application/vnd.microsoft.appconfig.ff+json;charset=utf-8. For Key Value reference, the value should be application/vnd.microsoft.appconfig.keyvaultref+json;charset=utf-8. Otherwise, it\'s optional.')
// param contentType string = 'the-content-type'

// @description('Adds tags for the key-value resources. It\'s optional')
// param tags object = {
//   tag1: 'tag-value-1'
//   tag2: 'tag-value-2'
// }

resource configStore 'Microsoft.AppConfiguration/configurationStores@2021-10-01-preview' = {
  name: devcenter_appconfig_name
  location: location
  sku: {
    name: 'standard'
  }
}

// resource configStoreKeyValue 'Microsoft.AppConfiguration/configurationStores/keyValues@2021-10-01-preview' = [for (item, i) in keyValueNames: {
//   parent: configStore
//   name: item
//   properties: {
//     value: keyValueValues[i]
//     contentType: contentType
//     tags: tags
//   }
// }]

// output reference_key_value_value string = configStoreKeyValue[0].properties.value
// output reference_key_value_object object = configStoreKeyValue[1]
