targetScope = 'resourceGroup'

@description('Managed Identity Client Id. The resource ID of the user assigned identity to be used for the deployment.')
param managedIdentityClientId string

@description('Managed Identity Name. The name of the user assigned identity to be used for the deployment.')
param managedIdentityName string

@description('Kubelet Identity Client Id. The client ID of the user assigned identity to be used for kubelet identity.')
param kubeletIdentityClientId string = ''

@description('Kubelet Identity Object Id. The object ID of the user assigned identity to be used for kubelet identity.')
param kubeletIdentityObjectId string = ''

resource managedIdentity 'Microsoft.ManagedIdentity/userAssignedIdentities@2025-01-31-preview' existing = {
  name: managedIdentityName
}

resource kubeletIdenityManagedIdentityOperatorRoleAssignmentToRG 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(kubeletIdentityClientId, managedIdentityClientId, 'ManagedIdentityOperator')
  scope: managedIdentity
  properties: {
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', 'f1a07417-d97a-45cb-824c-7a7467783830') // Managed Identity Operator
    principalId: kubeletIdentityObjectId
    principalType: 'ServicePrincipal'
  }
}
