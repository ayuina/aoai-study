param prefix string = 'ayuina0726a'
param region string = 'japaneast'
param aoaiRegion string = 'eastus'

var appSvcName = '${prefix}-web'
var appSvcPlanName = '${prefix}-asp'

var cosmosAccountName = '${prefix}-cosmos'
var cosmosDatabaseName = 'Database1'
var cosmosContainerName = 'Container1'

var apimName = '${prefix}-apim'

var aoaiName = '${prefix}-${aoaiRegion}-aoai'
var aoaiModelName = 'gpt-35-turbo'
var aoaiModelDeploy = 'g35t'
var aoaiModelVersion = '0613'

var logAnalyticsName = '${prefix}-laws'
var appInsightsName = '${prefix}-ai'

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

resource appinsights 'Microsoft.Insights/components@2020-02-02' = {
  name: appInsightsName
  location: region
  kind: 'web'
  properties:{
    Application_Type: 'web'
    WorkspaceResourceId: logAnalytics.id
    publicNetworkAccessForIngestion: 'Enabled'
    publicNetworkAccessForQuery: 'Enabled'
  }
}

resource asp 'Microsoft.Web/serverfarms@2022-03-01' = {
  name: appSvcPlanName
  location: region
  sku: {
    name: 'S1'
    capacity: 1
  }
}

resource web 'Microsoft.Web/sites@2022-03-01' = {
  name: appSvcName
  location: region
  properties:{
    serverFarmId: asp.id
    clientAffinityEnabled: false
    siteConfig: {
      netFrameworkVersion: 'v7.0'
      ftpsState: 'Disabled'
      use32BitWorkerProcess: false
    }
  }
}

resource metadata 'Microsoft.Web/sites/config@2022-03-01' = {
  name: 'metadata'
  parent: web
  properties: {
    CURRENT_STACK: 'dotnet'
  }
}

resource appsettings 'Microsoft.Web/sites/config@2022-03-01' = {
  name: 'appsettings'
  parent: web
  properties: {
    APPINSIGHTS_INSTRUMENTATIONKEY: appinsights.properties.InstrumentationKey
    APPLICATIONINSIGHTS_CONNECTION_STRING: appinsights.properties.ConnectionString
    ApplicationInsightsAgent_EXTENSION_VERSION: '~3'
    XDT_MicrosoftApplicationInsights_Mode: 'Recommended'
    XDT_MicrosoftApplicationInsights_PreemptSdk: '1'
  }
}

resource aoai 'Microsoft.CognitiveServices/accounts@2023-05-01' = {
  name: aoaiName
  location: aoaiRegion
  sku: {
    name: 'S0'
  }
  kind: 'OpenAI'
  properties: {
    customSubDomainName: aoaiName
    publicNetworkAccess: 'Enabled'
  }
}

resource chatgpt 'Microsoft.CognitiveServices/accounts/deployments@2023-05-01' = {
  parent: aoai
  name: aoaiModelDeploy
  sku: {
    name: 'Standard'
    capacity: 10
  }
  properties: {
    model: {
      format: 'OpenAI'
      name: aoaiModelName
      version: aoaiModelVersion
    }
  }
}

resource aoaiDiag 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = {
  name: '${aoai.name}-diag'
  scope: aoai
  properties: {
    workspaceId: logAnalytics.id
    logAnalyticsDestinationType: 'Dedicated'
    logs: [
      {
        category: null
        categoryGroup: 'Audit'
        enabled: true
      }
      {
        category: null
        categoryGroup: 'allLogs'
        enabled: true
      }
    ]
    metrics: [
      {
          category: 'AllMetrics'
          enabled: true
          timeGrain: null
      }
    ]
  }
}

resource cosmosAccount 'Microsoft.DocumentDB/databaseAccounts@2023-04-15' = {
  name: cosmosAccountName
  location: region
  kind: 'GlobalDocumentDB'
  properties: {
    databaseAccountOfferType: 'Standard'
    consistencyPolicy: {
      defaultConsistencyLevel: 'Session'
    }
    locations: [
      {
        locationName: region
        failoverPriority: 0
        isZoneRedundant: false
      }
    ]
  }

  resource database 'sqlDatabases' = {
    name: cosmosDatabaseName
    properties: {
      resource: {
        id: cosmosDatabaseName
      }
    }

    resource container 'containers' = {
      name: cosmosContainerName
      properties: {
        resource: {
          id: cosmosContainerName
          partitionKey: {
            paths: [
              '/userid'
            ]
            kind: 'Hash'
          }
        }
      }
    }
  }
}


resource apiman 'Microsoft.ApiManagement/service@2023-03-01-preview' = {
  name: apimName
  location: region
  sku: {
    name: 'Developer'
    capacity: 1
  }
  properties: {
    publisherName: prefix
    publisherEmail: '${prefix}@${prefix}.local'
  }

  resource ailogger 'loggers' = {
    name: '${appInsightsName}-logger'
    properties: {
      loggerType: 'applicationInsights'
      resourceId: appinsights.id
      credentials: {
        instrumentationKey: appinsights.properties.InstrumentationKey
      }
    }
  }
  
  resource diag 'diagnostics' = {
    name: 'applicationinsights'
    properties: {
      loggerId: ailogger.id
      alwaysLog: 'allErrors'
      logClientIp: true
      verbosity: 'verbose'
    }
  }
}

resource apimDiag 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = {
  name: '${apiman.name}-diag'
  scope: apiman
  properties: {
    workspaceId: logAnalytics.id
    logAnalyticsDestinationType: 'Dedicated'
    logs: [
      {
        category: 'GatewayLogs'
        enabled: true
      }
      {
        category: 'WebSocketConnectionLogs'
        enabled: true
      }
    ]
    metrics: [
      {
         category: 'AllMetrics'
         enabled: true
      }
    ]
  }

}
