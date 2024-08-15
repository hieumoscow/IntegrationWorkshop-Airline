@description('Location for main resources.')
param location string = resourceGroup().location

@description('A prefix to add to the start of all resource names. Note: A "unique" suffix will also be added')
@minLength(3)
@maxLength(10)
param prefix string = 'ais'

@description('Tags to apply to all deployed resources')
param tags object = {}

param publisherEmail string = 'noreply@microsoft.com'

@allowed([
  'adf-cosmos'
  'none'
])
param datafactoryDeployment string = 'adf-cosmos'

var usablePrefix = toLower(trim(prefix))
var uniqueSuffix = uniqueString(resourceGroup().id, prefix)
var uniqueNameFormat = '${usablePrefix}-{0}-${uniqueSuffix}'
var uniqueShortNameFormat = '${usablePrefix}{0}${uniqueSuffix}'

resource logAnalytics 'Microsoft.OperationalInsights/workspaces@2022-10-01' = {
  name: format(uniqueNameFormat, 'logs')
  location: location
  tags: tags
  properties: {
    retentionInDays: 30
    sku: {
      name: 'PerGB2018'
    }
  }
}

resource appInsights 'Microsoft.Insights/components@2020-02-02-preview' = {
  name: format(uniqueNameFormat, 'insights')
  location: location
  tags: tags
  kind: 'web'
  properties: {
    Application_Type: 'web'
    WorkspaceResourceId: logAnalytics.id
  }
}

resource keyVault 'Microsoft.KeyVault/vaults@2023-07-01' = {
  name: take(format(uniqueShortNameFormat, 'kv'), 24)
  location: location
  tags: tags
  properties: {
    sku: {
      family: 'A'
      name: 'standard'
    }
    tenantId: tenant().tenantId
    accessPolicies: []
  }
}

resource serviceBus 'Microsoft.ServiceBus/namespaces@2022-10-01-preview' = {
  name: format(uniqueNameFormat, 'sb')
  location: location
  tags: tags
  properties: {}
  sku: {
    name: 'Standard'
  }
  resource inboundTopic 'topics' = {
    name: 'inbound'
    properties: {
    }
  }
}

resource apimv2 'Microsoft.ApiManagement/service@2023-05-01-preview' = {
  name: format(uniqueNameFormat, 'apimv2')
  location: location
  sku: {
    capacity: 1
    name: 'BasicV2'
  }
  properties: {
    publisherEmail: publisherEmail
    publisherName: prefix
  }
  resource appins 'loggers' = {
    name: 'appins'
    properties: {
      loggerType: 'applicationInsights'
      credentials: {
        instrumentationKey: appInsights.properties.InstrumentationKey
      }
    }
  }
}

resource storage 'Microsoft.Storage/storageAccounts@2023-04-01' = {
  #disable-next-line BCP334
  name: take(format(uniqueShortNameFormat, 'st'), 24)
  location: location
  tags: tags
  kind: 'StorageV2'
  sku: {
    name: 'Standard_LRS'
  }
  properties: {
    allowBlobPublicAccess: false
    defaultToOAuthAuthentication: true
    supportsHttpsTrafficOnly: true
    minimumTlsVersion: 'TLS1_2'
  }

  resource blobs 'blobServices' existing = {
    name: 'default'
    resource functionAppContainer 'containers' = {
      name: 'app-package-${format(uniqueNameFormat, 'func')}'
    }
  }
}

resource logicAppPlan 'Microsoft.Web/serverfarms@2023-12-01' = {
  name: format(uniqueNameFormat, 'logicapp')
  location: location
  tags: tags
  sku: {
    tier: 'WorkflowStandard'
    name: 'WS1'
  }
  properties: {
    maximumElasticWorkerCount: 3
    zoneRedundant: false
  }
}

resource logicApp 'Microsoft.Web/sites@2023-12-01' = {
  name: format(uniqueNameFormat, 'logicapp')
  location: location
  tags: tags
  kind: 'functionapp,workflowapp'
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    serverFarmId: logicAppPlan.id
    httpsOnly: true
    clientAffinityEnabled: false
    siteConfig: {
      use32BitWorkerProcess: false
      ftpsState: 'FtpsOnly'
      netFrameworkVersion: 'v6.0'
      appSettings: [
        { name: 'APP_KIND', value: 'workflowApp' }
        {
          name: 'AzureFunctionsJobHost__extensionBundle__id'
          value: 'Microsoft.Azure.Functions.ExtensionBundle.Workflows'
        }
        { name: 'AzureFunctionsJobHost__extensionBundle__version', value: '[1.*, 2.0.0)' }
        { name: 'FUNCTIONS_EXTENSION_VERSION', value: '~4' }
        { name: 'FUNCTIONS_WORKER_RUNTIME', value: 'node' }
        { name: 'WEBSITE_NODE_DEFAULT_VERSION', value: '~18' }
        {
          name: 'AzureWebJobsStorage'
          value: 'DefaultEndpointsProtocol=https;AccountName=${storage.name};AccountKey=${storage.listKeys().keys[0].value};EndpointSuffix=core.windows.net'
        }
        {
          name: 'WEBSITE_CONTENTAZUREFILECONNECTIONSTRING'
          value: 'DefaultEndpointsProtocol=https;AccountName=${storage.name};AccountKey=${storage.listKeys().keys[0].value};EndpointSuffix=core.windows.net'
        }
        { name: 'WEBSITE_CONTENTSHARE', value: format(uniqueShortNameFormat, 'logicapp') }
        { name: 'APPLICATIONINSIGHTS_CONNECTION_STRING', value: appInsights.properties.ConnectionString }
      ]
    }
  }
  resource disableBasicScm 'basicPublishingCredentialsPolicies' = {
    name: 'scm'
    properties: {
      allow: false
    }
  }
  resource disableBasicFtp 'basicPublishingCredentialsPolicies' = {
    name: 'ftp'
    properties: {
      allow: false
    }
  }
}

// Can be swapped into an Azure Function

resource logicApp2 'Microsoft.Web/sites@2023-12-01' = {
  name: format(uniqueNameFormat, 'otherlogic')
  location: location
  tags: tags
  kind: 'functionapp,workflowapp'
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    serverFarmId: logicAppPlan.id
    httpsOnly: true
    clientAffinityEnabled: false
    siteConfig: {
      use32BitWorkerProcess: false
      ftpsState: 'FtpsOnly'
      netFrameworkVersion: 'v6.0'
      appSettings: [
        { name: 'APP_KIND', value: 'workflowApp' }
        {
          name: 'AzureFunctionsJobHost__extensionBundle__id'
          value: 'Microsoft.Azure.Functions.ExtensionBundle.Workflows'
        }
        { name: 'AzureFunctionsJobHost__extensionBundle__version', value: '[1.*, 2.0.0)' }
        { name: 'FUNCTIONS_EXTENSION_VERSION', value: '~4' }
        { name: 'FUNCTIONS_WORKER_RUNTIME', value: 'node' }
        { name: 'WEBSITE_NODE_DEFAULT_VERSION', value: '~18' }
        {
          name: 'AzureWebJobsStorage'
          value: 'DefaultEndpointsProtocol=https;AccountName=${storage.name};AccountKey=${storage.listKeys().keys[0].value};EndpointSuffix=core.windows.net'
        }
        {
          name: 'WEBSITE_CONTENTAZUREFILECONNECTIONSTRING'
          value: 'DefaultEndpointsProtocol=https;AccountName=${storage.name};AccountKey=${storage.listKeys().keys[0].value};EndpointSuffix=core.windows.net'
        }
        { name: 'WEBSITE_CONTENTSHARE', value: format(uniqueShortNameFormat, 'otherlogic') }
        { name: 'APPLICATIONINSIGHTS_CONNECTION_STRING', value: appInsights.properties.ConnectionString }
      ]
    }
  }
  resource disableBasicScm 'basicPublishingCredentialsPolicies' = {
    name: 'scm'
    properties: {
      allow: false
    }
  }
  resource disableBasicFtp 'basicPublishingCredentialsPolicies' = {
    name: 'ftp'
    properties: {
      allow: false
    }
  }
}


resource dataExplorer 'Microsoft.Kusto/clusters@2023-08-15' = {
  name: take(format(uniqueNameFormat, 'ade'), 24)
  location: location
  tags: tags
  sku: {
    name: 'Dev(No SLA)_Standard_E2a_v4'
    tier: 'Basic'
    capacity: 1
  }
  zones: pickZones('Microsoft.Kusto', 'clusters', location)
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    enableAutoStop: false
    enableStreamingIngest: false
    enablePurge: false
    enableDiskEncryption: false
    enableDoubleEncryption: false
    trustedExternalTenants: []
  }
  resource busprocDatabase 'databases@2023-08-15' = {
    name: 'businessprocesstracking'
    location: location
    kind: 'ReadWrite'
    properties: {
    }
  }
}

resource integrationEnvironment 'Microsoft.IntegrationSpaces/spaces@2023-11-14-preview' = {
  name: format(uniqueNameFormat, 'intenv')
  location: location
  tags: tags
  properties: {
    description: '${prefix} Integration Environment'
  }
}

module datafactory './adf-cosmos.bicep' = if (toLower(datafactoryDeployment) == 'adf-cosmos') {
  name: '${uniqueString(deployment().name)}-adf'
  scope: resourceGroup()
  params: {
    location: location
    tags: tags
    uniqueNameFormat: uniqueNameFormat
    uniqueShortNameFormat: uniqueShortNameFormat
  }
}
