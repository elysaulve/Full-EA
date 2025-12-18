// ========== Redis Cache ========== //
targetScope = 'resourceGroup'

@description('Solution Name.')
param solutionName string = substring(guid(subscription().id, tenant().tenantId), 0, 15)

@description('Solution Location.')
param solutionLocation string = resourceGroup().location

var rcName = '${ solutionName }-rc'

@description('Managed Identity Id. The resource ID of the user assigned managed identity to be used by the AKS cluster.')
param managedIdentityId string

@minValue(0)
@maxValue(6)
@description('SKU Capacity. The size of the Redis cache to deploy. Valid values are from 0 to 6, depending on the SKU selected.')
param skuCapacity int = 0

@allowed([
  'C'
  'P'
])
@description('SKU Family. The family of the SKU to deploy. Valid values are C, P, and F.')
param skuFamily string = 'C'

@description('SKU Name. C = Basic/Standard, P = Premium.')
@allowed([
  'Basic'
  'Standard'
  'Premium'
])
param skuName string = 'Standard'


@description('Disable Access Key Authentication for Redis. Authentication to Redis through access keys is disabled when set as true. Default value is false.')
param disableAccessKeyAuthentication bool = false

@description('Enable Non SSL Port. If true, enables non-SSL port (6379) on the cache. Default value is false.')
param enableNonSslPort bool = false

@description('Minimum TLS Version. Specifies the minimum TLS version required for clients to connect to cache.')
param minimumTlsVersion string = '1.2'

@description('Public Network Access. Whether requests from Public Network are allowed.')
param publicNetworkAccess string = 'Disabled'

@description('AAD Enabled. Specifies whether to enable AAD authentication for Redis cache.')  
param aadEnabled string = 'true'

@description('Max Fragmentation Memory Reserved. The percentage of memory that is reserved for fragmentation. Default is 10%')
param maxFragmentationMemoryReserved string = '25'

@description('Max Memory Delta. The percentage of memory that is allowed as a delta above the max memory limit. Default is 10%')
param maxMemoryDelta string = '25'

@description('Notify Keyspace Events. Configures the keyspace notifications to be enabled on the cache. For more information, see https://redis.io/.')
param notifyKeyspaceEvents string = 'Exe'

resource redisCache 'Microsoft.Cache/redis@2024-11-01' = {
  name: rcName
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
  properties: {
    sku: {
      capacity: skuCapacity
      family: skuFamily
      name: skuName
    }
    disableAccessKeyAuthentication: disableAccessKeyAuthentication
    enableNonSslPort: enableNonSslPort
    minimumTlsVersion: minimumTlsVersion
    publicNetworkAccess: publicNetworkAccess
    redisConfiguration: {
      'aad-enabled': aadEnabled     
      'maxfragmentationmemory-reserved': maxFragmentationMemoryReserved
      'maxmemory-delta': maxMemoryDelta
      'notify-keyspace-events': notifyKeyspaceEvents
    }
    redisVersion: 'latest'
    updateChannel: 'Stable'
    zonalAllocationPolicy: 'Automatic'
  }
}

output redisCacheOutput object = {
  name: redisCache.name
  id: redisCache.id
  properties: redisCache.properties
}
