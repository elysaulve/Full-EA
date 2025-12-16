// ========== Cosmos DB Services ========== //
targetScope = 'resourceGroup'

@description('Solution Name.')
param solutionName string = substring(guid(subscription().id, tenant().tenantId), 0, 15)

@description('Solution Location.')
param solutionLocation string = resourceGroup().location

var cdbName = '${ solutionName }-ks'

@description('Managed Identity Id. The resource ID of the user assigned managed identity to be used by the AKS cluster.')
param managedIdentityId string

@allowed([
  'GlobalDocumentDB'
  'MongoDB'
  'Parse'
])
@description('Kind of Cosmos DB account. The default value is \'MongoDB\'.')
param kind string = 'MongoDB'

@allowed([
  'FullFidelity'
  'WellDefined'
])
@description('Schema Type for Analytical Storage. The default value is \'FullFidelity\'.')
param schemaType string = 'FullFidelity'

@description('Backup start time for Cosmos DB.')
param backupStartTime string = '${substring(utcNow(), 0, 10)}T00:00:00Z'

@description('Backup interval in minutes for Cosmos DB. An integer representing the interval in minutes between two backups. The default value is 60 minutes.')
param backupIntervalInMinutes int = 60

@description('Backup retention interval in hours for Cosmos DB. An integer representing the time (in hours) that each backup is retained. The default value is 8 hours.')
param backupRetentionIntervalInHours int = 8

@allowed([
  'Geo'
  'Local'
  'Zone'
])
@description('Backup storage redundancy for Cosmos DB. The default value is \'Zone\'.')
param backupStorageRedundancy string = 'Zone'

@description('Capability Name for Cosmos DB. The default value is \'EnableMongo\'.')
param capabilityName string = 'EnableMongo'

@allowed([
  'Provisioned'
  'Serverless'
])
@description('Capacity Mode for Cosmos DB. The default value is \'Serverless\'.')
param capacityMode string = 'Serverless'

@description('Total Throughput Limit for Cosmos DB. For Provisioned capacity mode, set a value between 400 and 1000000. For Serverless capacity mode, set to -1.')
param totalThroughputLimit int = capacityMode == 'Provisioned' ? 1000 : -1

@allowed([
  'Strong'
  'BoundedStaleness'
  'Session'
  'ConsistentPrefix'
  'Eventual'
])
@description('Default Consistency Level for Cosmos DB. The default value is \'Eventual\'.')
param defaultConsistencyLevel string = 'Eventual'

@description('Default Priority Level for Cosmos DB. The default value is \'Low\'. Only applicable for accounts with provisioned throughput.')
param defaultPriorityLevel string = 'Low'

@description('Enable FUll-Text Query. Disable Key Based Metadata Write Access for Cosmos DB.')
param enableFullTextQuery string = 'True'

@description('Disable Key Based Metadata Write Access for Cosmos DB. The default value is false.')
param disableKeyBasedMetadataWriteAccess bool = false

@description('Disable Local Auth. Opt-out of local authentication and ensure only MSI and AAD can be used exclusively for authentication.')
param disableLocalAuth bool = false

@description('Enable All Versions And Deletes Change Feed. Flag to indicate if All Versions and Deletes Change feed feature is enabled on the account')
param enableAllVersionsAndDeletesChangeFeed bool = false

@description('Enable Analytical Storage. Flag to indicate whether to enable storage analytics.')
param enableAnalyticalStorage bool = true

@description('Enable Automatic Failover. Enables automatic failover of the write region in the rare event that the region is unavailable due to an outage. Automatic failover will result in a new write region for the account and is chosen based on the failover priorities configured for the account.')
param enableAutomaticFailover bool = true

@description('Enable Burst Capacity. Enables burst capacity for serverless Cosmos DB accounts to handle occasional bursts of traffic beyond the provisioned throughput limits.')
param enableBurstCapacity bool = true

@description('Enable Free Tier. Flag to indicate whether to enable free tier for the Cosmos DB account.')
param enableFreeTier bool = false

@description('Enable Materialized Views. Flag to indicate whether to enable materialized views for the Cosmos DB account.')
param enableMaterializedViews bool = false

@description('Enable Multiple Write Locations. Flag to indicate whether to enable multiple write locations for the Cosmos DB account.')
param enableMultipleWriteLocations bool = false

@description('Enable Partition Merge. Flag to indicate whether to enable partition merge for the Cosmos DB account.')
param enablePartitionMerge bool = true

@description('Enable Per Region Per Partition Autoscale. Flag to indicate whether to enable per region per partition autoscale for the Cosmos DB account. Only applicable for accounts with provisioned throughput.')
param enablePerRegionPerPartitionAutoscale bool = false

@description('Enable Priority Based Execution. Flag to indicate whether to enable priority based execution for the Cosmos DB account. Only applicable for accounts with provisioned throughput.')
param enablePriorityBasedExecution bool = false

@description('Key Vault Key Ref. The URI of the customer-managed key in Azure Key Vault to be used for encryption at rest.')
param keyVaultKeyRef string = ''

@description('Public Network Access. Specifies whether to allow public network access to the Cosmos DB account. The default value is \'Disabled\'.')
@allowed([
  'Enabled'
  'Disabled'
  'SecuredByPerimeter'
])
param publicNetworkAccess string = 'Disabled'

resource cosmosDB 'Microsoft.DocumentDB/databaseAccounts@2025-11-01-preview' = {
  name: cdbName
  location: solutionLocation
  tags: {
    app: solutionName
    location: solutionLocation
  }
  identity: {
    type: 'UserAssigned'
    userAssignedIdentities: {
      '${managedIdentityId}': {}
    }
  }
  kind: kind
  properties: {
    analyticalStorageConfiguration: {
      schemaType: schemaType
    }
    apiProperties: {
      serverVersion: '7.0'
    }
    backupPolicy: {
      migrationState: {
        startTime: backupStartTime
        status: 'InProgress'
        targetType: 'Periodic'
      }
      type: 'Periodic'
      periodicModeProperties: {
        backupIntervalInMinutes: backupIntervalInMinutes
        backupRetentionIntervalInHours: backupRetentionIntervalInHours
        backupStorageRedundancy: backupStorageRedundancy
      }
    }
    capabilities: [
      {
        name: capabilityName
      }
    ]
    capacity: {
      totalThroughputLimit: totalThroughputLimit
    }
    capacityMode: capacityMode
    consistencyPolicy: {
      defaultConsistencyLevel: defaultConsistencyLevel
      //maxIntervalInSeconds: int
      //maxStalenessPrefix: int
    }
    /*cors: [
      {
        allowedHeaders: 'string'
        allowedMethods: 'string'
        allowedOrigins: 'string'
        exposedHeaders: 'string'
        maxAgeInSeconds: int
      }
    ]*/
    createMode: 'Default'
    databaseAccountOfferType: 'Standard'
    defaultIdentity: 'UserAssignedIdentity=${managedIdentityId}'
    //defaultPriorityLevel: defaultPriorityLevel
    diagnosticLogSettings: {
      enableFullTextQuery: enableFullTextQuery
    }
    disableKeyBasedMetadataWriteAccess: disableKeyBasedMetadataWriteAccess
    disableLocalAuth: disableLocalAuth
    enableAllVersionsAndDeletesChangeFeed: enableAllVersionsAndDeletesChangeFeed
    enableAnalyticalStorage: enableAnalyticalStorage
    enableAutomaticFailover: enableAutomaticFailover
    enableBurstCapacity: enableBurstCapacity
    enableFreeTier: enableFreeTier
    enableMaterializedViews: enableMaterializedViews
    enableMultipleWriteLocations: enableMultipleWriteLocations
    enablePartitionMerge: enablePartitionMerge
    enablePerRegionPerPartitionAutoscale: enablePerRegionPerPartitionAutoscale
    enablePriorityBasedExecution: enablePriorityBasedExecution
    keyVaultKeyUri: keyVaultKeyRef
    locations: [
      {
        failoverPriority: 0
        isZoneRedundant: false
        locationName: 'eastus'
      }
    ]
    minimalTlsVersion: 'Tls12'
    networkAclBypass: 'None'
    publicNetworkAccess: publicNetworkAccess
  }
}

output cosmosDbOutput object = {
  name: cosmosDB.name
  id: cosmosDB.id
  location: cosmosDB.location
  identity: cosmosDB.identity
  kind: cosmosDB.kind
  properties: cosmosDB.properties
}
