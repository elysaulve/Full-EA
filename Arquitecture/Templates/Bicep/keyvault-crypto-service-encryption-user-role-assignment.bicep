targetScope = 'resourceGroup'

@description('Keyvault Name. The name of the Keyvault where the encryption key is stored.')
param keyvaultName string

@description('Managed Identity Id. The client ID of the user assigned identity to be used for kubelet identity.')
param managedIdentityId string = ''

@description('Managed Identity Principal Id. The object ID of the user assigned identity to be used for kubelet identity.')
param managedIdentityPrincipalId string = ''

resource keyvault 'Microsoft.KeyVault/vaults@2025-05-01' existing = {
  name: keyvaultName
}

resource keyvaultCryptoServiceEncryptionUserRoleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(managedIdentityId, keyvault.id, 'Key Vault Crypto Service Encryption User')
  scope: keyvault
  properties: {
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', 'e147488a-f6f5-4113-8e2d-b22465e65bf6') // Key Vault Crypto Service Encryption User
    principalId: managedIdentityPrincipalId
    principalType: 'ServicePrincipal'
  }
}
