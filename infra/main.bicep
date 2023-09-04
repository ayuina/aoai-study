targetScope = 'subscription'

param prefix string = 'ayuina0726b'
param region string = 'japaneast'
param aoaiRegion string = 'japaneast'

var rgName = '${prefix}-rg'
var aoaiSpec = loadTextContent('./aoai-specs/openai-spec.2023-07-01-preview.json')
var aoaiPolicy = loadTextContent('./aoai-specs/openai-policy.xml')

resource rg 'Microsoft.Resources/resourceGroups@2022-09-01' = {
  name: rgName
  location: region
}

module monitor 'modules/monitor.bicep' = {
  scope: rg
  name: 'monitor'
  params:{
    prefix: prefix
    region: region
  }
}

module webapp 'modules/webapp.bicep' = {
  scope: rg
  name: 'webapp'
  params:{
    region: region
    prefix: prefix
    logAnalyticsName: monitor.outputs.LogAnalyticsName
  }
}

module aoai 'modules/openai.bicep' = {
  scope: rg
  name: 'aoai'
  params:{
    aoaiRegion: aoaiRegion
    prefix: prefix
    logAnalyticsName: monitor.outputs.LogAnalyticsName
  }
}

module cosmos 'modules/cosmos.bicep' = {
  scope: rg
  name: 'cosmos'
  params:{
    region: region
    prefix: prefix
    logAnalyticsName: monitor.outputs.LogAnalyticsName
  }
}

module apim 'modules/apim.bicep' = {
  scope: rg
  name: 'apim'
  params:{
    region: region
    prefix: prefix
    logAnalyticsName: monitor.outputs.LogAnalyticsName
  }
}

module apim_aoai 'modules/apim-aoai.bicep' = {
  scope: rg
  name: 'apim-aoai'
  params:{
    apimName: apim.outputs.apimName
    aoaiName: aoai.outputs.aoaiAccountName
    aoaiSpec: aoaiSpec
    aoaiPolicy: aoaiPolicy
  }
}

output RESOURCE_GROUP_NAME string = rgName
output TARGET_REGION string = region
output AOAI_REGION string = region
output WEBAPP_NAME string = webapp.outputs.webAppName
output WEBAPP_ENDPOINT string = webapp.outputs.webAppEndpoint
