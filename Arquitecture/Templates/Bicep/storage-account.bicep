// ========== Storage Account ========== //
targetScope = 'resourceGroup'

@minLength(3)
@maxLength(15)
@description('Solution Name')
param solutionName string

@description('Solution Location')
param solutionLocation string = resourceGroup().location

@description('SKU Name. The SKU name. Required for account creation; optional for update. Note that in older versions, SKU name was called accountType.')
@allowed([  
  'Premium_LRS'
  'Premium_ZRS'
  'Standard_GRS'
  'Standard_GZRS'
  'Standard_LRS'
  'Standard_RAGRS'
  'Standard_RAGZRS'
  'Standard_ZRS'
])
param skuName string = 'Standard_LRS'

@description('SKU Tier. The SKU name. Required for account creation; optional for update. Note that in older versions, SKU name was called accountType.')
@allowed([  
  'Premium'
  'Standard'
])
param skuTier string = 'Standard'

@description('Name')
param saName string = '${ solutionName }sa'

@description('Managed Identity Id. Resource identifier of the UserAssigned identity to be used for the storage account deploymend and associated with server-side encryption on the storage account.')
param managedIdentityId string = ''

@description('Key Name. The name of KeyVault key.')
param keyName string = 'encryptionKey'

@description('Key Vault URI. The Uri of KeyVault.')
param keyVaultUri string = ''

@description('Key Version. The version of KeyVault key.')
param keyVersion string = ''

@description('Allow Blob Public Access. Allow or disallow public access to all blobs or containers in the storage account. The default interpretation is true for this property.')
param allowBlobPublicAccess bool = true

@description('Is HNS Enabled. Account HierarchicalNamespace enabled if sets to true.')
param isHnsEnabled bool = true

resource storageAccount 'Microsoft.Storage/storageAccounts@2024-01-01' = {
  name: saName
  location: solutionLocation
  sku: {
    name: skuName
    tier: skuTier
  }
  kind: 'StorageV2'
  identity: {
    type: 'UserAssigned'
    userAssignedIdentities: {
      '${managedIdentityId}' : {}
    }
  }
  properties: {
    minimumTlsVersion: 'TLS1_2'
    allowBlobPublicAccess: allowBlobPublicAccess
    isHnsEnabled: isHnsEnabled
    networkAcls: {
      bypass: 'AzureServices'
      virtualNetworkRules: []
      ipRules: []
      defaultAction: 'Allow'
    }
    supportsHttpsTrafficOnly: true
    encryption: {
      identity: {        
        userAssignedIdentity: managedIdentityId 
      }
      services: {
        file: {
          keyType: 'Account'
          enabled: true
        }
        blob: {
          keyType: 'Account'
          enabled: true
        }
      }
      keySource: 'Microsoft.KeyVault'
      keyvaultproperties: {
        keyname: keyName
        keyvaulturi: keyVaultUri
        keyversion: keyVersion
      }
    }    
  }
}

resource storageAccountBlobServicesDefault 'Microsoft.Storage/storageAccounts/blobServices@2024-01-01' = {
  parent: storageAccount
  name: 'default'
  properties: {    
    cors: {
      corsRules: []
    }
    deleteRetentionPolicy: {
      allowPermanentDelete: true
      enabled: true
      days: 30
    }
  }
}

resource storageAccountBlobServicesFylesysContainer 'Microsoft.Storage/storageAccounts/blobServices/containers@2024-01-01' = {
  parent: storageAccountBlobServicesDefault
  name: 'filesys'
  properties: {
    defaultEncryptionScope: '$account-encryption-key'
    denyEncryptionScopeOverride: false
    publicAccess: 'None'
  }
}

resource storageAccountBlobServicesPublicContainer 'Microsoft.Storage/storageAccounts/blobServices/containers@2024-01-01' = {
  parent: storageAccountBlobServicesDefault
  name: 'public'
  properties: {
    defaultEncryptionScope: '$account-encryption-key'
    denyEncryptionScopeOverride: false
    publicAccess: 'Blob'
  }
}

resource storageAccountFileServicesDefault 'Microsoft.Storage/storageAccounts/fileServices@2024-01-01' = {
  parent: storageAccount
  name: 'default'  
  properties: {
    cors: {
      corsRules: [        
      ]
    }  
    shareDeleteRetentionPolicy: {
      allowPermanentDelete: true
      days: 60
      enabled: true
    }
  }
}

resource storageAccountFileServiceContainerInstanceShare 'Microsoft.Storage/storageAccounts/fileServices/shares@2024-01-01' = {  
  parent: storageAccountFileServicesDefault
  name: 'containerinstance'
  properties: {
    accessTier: 'cool'
    enabledProtocols: 'SMB'
    metadata: {}  
    shareQuota: 8    
  }
}

var key = storageAccount.listKeys().keys[0].value
var storageAccountString = 'DefaultEndpointsProtocol=https;AccountName=${storageAccount.name};AccountKey=${key};EndpointSuffix=${environment().suffixes.storage}'

output storageAccountOutput object = {
  id: storageAccount.id
  name: saName
  sku: skuName
  uri: storageAccount.properties.primaryEndpoints.web  
  dfs: storageAccount.properties.primaryEndpoints.dfs
  storageAccountName:saName
  key: key
  connectionString: storageAccountString
  dataContainer: storageAccountBlobServicesDefault.name
  blobs: [   
    { 
      id: storageAccountBlobServicesPublicContainer.id
      name: storageAccountBlobServicesPublicContainer.name
    }
  ]
  shares: [
    {
      id: storageAccountFileServiceContainerInstanceShare.id
      name: storageAccountFileServiceContainerInstanceShare.name
    }
  ]
}

