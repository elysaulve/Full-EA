// ========== Virtual Network ========== //
targetScope = 'resourceGroup'

@description('Kubelet Identity Client Id. The client ID of the user assigned identity to be used for kubelet identity.')
param kubeletIdentityClientId string = ''

@description('Kubelet Identity Object Id. The object ID of the user assigned identity to be used for kubelet identity.')
param kubeletIdentityObjectId string = ''

resource kubeletIdentityReaderRoleAssignmentToRG 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(kubeletIdentityClientId, resourceGroup().name, 'Reader')
  scope: resourceGroup()
  properties: {
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', 'acdd72a7-3385-48ef-bd42-f606fba81ae7') // Reader
    principalId: kubeletIdentityObjectId
    principalType: 'ServicePrincipal'
  }
}
