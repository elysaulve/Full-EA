// ========== Data Factory ========== //
targetScope = 'resourceGroup'

@minLength(3)
@maxLength(15)
@description('Solution Name')
param solutionName string

@description('Solution Location')
param solutionLocation string = resourceGroup().location

@description('Managed Identity Id. The Azure resource Id of the managed identity used for deployment.')
param managedIdentityId string

@allowed([
  'Enabled'
  'Disabled'
])
@description('Public Network Access. Whether or not public endpoint access is allowed for this data factory.')
param publicNetworkAccess string = 'Disabled'

@description('Encryption Key Name. The name of KeyVault key.')
param encryptionKeyName string = 'encryptionKey'

@description('Encryption Key Version. The version of KeyVault key.')
param encryptionKeyVersion string = ''

@description('Encryption Key Vault URI. The Uri of KeyVault.')
param encryptionKeyVaultUri string = ''

@description('Name')
param dfName string = '${ solutionName }-df'

resource dataFactory 'Microsoft.DataFactory/factories@2018-06-01' = {
  name: dfName
  location: solutionLocation
  identity: {
    type: 'UserAssigned'
    userAssignedIdentities: {
      '${ managedIdentityId }' : {}
    }
  }
  properties: {
    encryption: {
      identity: {
        userAssignedIdentity: managedIdentityId
      }
      keyName: encryptionKeyName
      keyVersion: encryptionKeyVersion
      vaultBaseUrl: encryptionKeyVaultUri
    }
    publicNetworkAccess: publicNetworkAccess
  }
}

output dataFactoryOutput object = {
  id: dataFactory.id
  name: dataFactory.name
}
