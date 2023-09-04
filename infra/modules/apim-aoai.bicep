param apimName string
param aoaiName string
param aoaiSpecDocs array

var policyContent = loadTextContent('../aoai-specs/openai-policy.xml')

resource apim 'Microsoft.ApiManagement/service@2023-03-01-preview' existing = {
  name: apimName
}

resource aoai 'Microsoft.CognitiveServices/accounts@2023-05-01' existing = {
  name: aoaiName
}

resource nv 'Microsoft.ApiManagement/service/namedValues@2023-03-01-preview' = {
  parent: apim
  name: 'NV-AzureOpenAIKey'
  properties: {
    displayName: 'AzureOpenAIKey'
    value: aoai.listKeys().key1
    secret: true
  }
}

resource aoaiVS 'Microsoft.ApiManagement/service/apiVersionSets@2023-03-01-preview' = {
  parent: apim
  name: 'OpenAI'
  properties: {
    displayName: 'Azure OpenAI VersionSet'
    versioningScheme: 'Query'
    versionQueryName: 'api-version'
  }
}

resource openaiApis 'Microsoft.ApiManagement/service/apis@2023-03-01-preview' = [for (spec, idx) in aoaiSpecDocs: {
  parent: apim
  name: 'OpenAI-${json(spec).info.version}'
  properties: {
    path: 'openai'
    subscriptionRequired: true
    protocols: [
      'https'
    ]
    type: 'http'
    format: 'openapi'
    serviceUrl: '${aoai.properties.endpoint}openai'
    subscriptionKeyParameterNames: {
      header: 'Ocp-Apim-Subscription-Key'
    }
    value: spec
    apiVersionSetId: aoaiVS.id
    apiVersion: json(spec).info.version
  }
}]

resource openaiApiPolicies 'Microsoft.ApiManagement/service/apis/policies@2023-03-01-preview' = [for (spec, idx) in aoaiSpecDocs: {
  parent: openaiApis[idx]
  name: 'policy'
  properties: {
    format: 'rawxml'
    value: policyContent
  }
}]
