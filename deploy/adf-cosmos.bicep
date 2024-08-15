param location string
param tags object

param uniqueNameFormat string
param uniqueShortNameFormat string
param databaseThroughputRUs int = 400
param createTriggers bool = true

resource storage 'Microsoft.Storage/storageAccounts@2023-04-01' = {
  #disable-next-line BCP334
  name: take(format(uniqueShortNameFormat, 'adfin'), 24)
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
    resource inboundContainer 'containers' = {
      name: 'inbound-data'
    }
  }
}

resource cosmosDB 'Microsoft.DocumentDB/databaseAccounts@2021-11-15-preview' = {
  name: format(uniqueNameFormat, 'cosmos')
  location: location
  kind: 'GlobalDocumentDB'
  properties: {
    databaseAccountOfferType: 'Standard'
    locations: [
      {
        locationName: location
      }
    ]
  }
  resource Database 'sqlDatabases' = {
    name: 'processed-data'
    properties: {
      resource: {
        id: 'processed-data'
      }
      options: {
        throughput: databaseThroughputRUs
      }
    }
  }
}

resource datafactory 'Microsoft.DataFactory/factories@2018-06-01' = {
  name: format(uniqueNameFormat, 'datafactory')
  location: location
  tags: tags
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    publicNetworkAccess: 'Enabled'
  }

  resource cosmosLS 'linkedservices' = {
    name: 'cosmos-db'
    properties: {
      type: 'CosmosDb'
      typeProperties: {
        accountEndpoint: cosmosDB.properties.documentEndpoint
        #disable-next-line BCP036
        accountKey: cosmosDB.listKeys().primaryMasterKey
        database: cosmosDB::Database.name
      }
    }
  }

  resource storageLS 'linkedservices' = {
    name: 'storage-inbound'
    properties: {
      type: 'AzureBlobStorage'
      typeProperties: {
        connectionString: 'DefaultEndpointsProtocol=https;AccountName=${storage.name};AccountKey=${storage.listKeys().keys[0].value};EndpointSuffix=${environment().suffixes.storage}'
        containerUri: 'https://${storage.name}.blob.${environment().suffixes.storage}/${storage::blobs::inboundContainer.name}'
        accountKind: storage.kind
        authenticationType: 'AccountKey'
      }
    }
  }

  resource dailyTrigger 'triggers' = if (createTriggers) {
    name: 'daily-trigger'
    properties: {
      type: 'ScheduleTrigger'
      typeProperties: {
        recurrence: {
          timeZone: 'UTC'
          startTime: '2024-01-01T00:00:00'
          frequency: 'Day'
          interval: 1
          schedule: {
            minutes: [0]
            hours: [0]
          }
        }
      }
    }
  }

  resource blobEventTrigger 'triggers' = if (createTriggers) {
    name: 'blob-event-trigger'
    properties: {
      type: 'BlobEventsTrigger'
      typeProperties: {
        scope: storage.id
        events: [
          'Microsoft.Storage.BlobCreated'
        ]
        ignoreEmptyBlobs: true
        blobPathBeginsWith: '/${storage::blobs::inboundContainer.name}/blobs/'
      }
    }
  }
}
