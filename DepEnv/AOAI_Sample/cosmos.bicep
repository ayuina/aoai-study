param prefix string
param region string
param logAnalyticsName string

var cosmosAccountName = '${prefix}-cosmos'
var cosmosDatabaseName = 'Database1'
var cosmosContainerName = 'Container1'

resource logAnalytics 'Microsoft.OperationalInsights/workspaces@2022-10-01' existing = {
  name: logAnalyticsName
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
