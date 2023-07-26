param prefix string = 'ayuina0726a'
param region string = 'japaneast'
param aoaiRegion string = 'eastus'

var logAnalyticsName = '${prefix}-laws'

resource logAnalytics 'Microsoft.OperationalInsights/workspaces@2022-10-01' = {
  name: logAnalyticsName
  location: region
  properties:{
    sku:{
      name: 'PerGB2018'
    }
    retentionInDays: 30
    features: {
      enableLogAccessUsingOnlyResourcePermissions: true
    }
    workspaceCapping: {
      dailyQuotaGb: -1
    }
    publicNetworkAccessForIngestion: 'Enabled'
    publicNetworkAccessForQuery: 'Enabled'
  }
}

module webapp 'webapp.bicep' = {
  name: 'webapp'
  params:{
    region: region
    prefix: prefix
    logAnalyticsName: logAnalyticsName
  }
}

module aoai 'openai.bicep' = {
  name: 'aoai'
  params:{
    aoaiRegion: aoaiRegion
    prefix: prefix
    logAnalyticsName: logAnalyticsName
  }
}

module cosmos 'cosmos.bicep' = {
  name: 'cosmos'
  params:{
    region: region
    prefix: prefix
    logAnalyticsName: logAnalyticsName
  }
}

module apim 'apim.bicep' = {
  name: 'apim'
  params:{
    region: region
    prefix: prefix
    logAnalyticsName: logAnalyticsName
  }
}

