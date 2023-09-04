targetScope = 'subscription'

param prefix string
param region string
param aoaiRegion string

var rgName = '${prefix}-rg'

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

output RESOURCE_GROUP_NAME string = rgName
output TARGET_REGION string = region
output AOAI_REGION string = region
output WEBAPP_NAME string = webapp.outputs.webAppName
output WEBAPP_ENDPOINT string = webapp.outputs.webAppEndpoint
