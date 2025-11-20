targetScope = 'resourceGroup'

@description('Kubelet Identity Client Id. The client ID of the user assigned identity to be used for kubelet identity.')
param kubeletIdentityClientId string = ''

@description('Kubelet Identity Object Id. The object ID of the user assigned identity to be used for kubelet identity.')
param kubeletIdentityObjectId string = ''

@description('App Gateway Name. The name of the Application Gateway resource.')
param appGatewayName string

@description('App Gateway Subnet Name. The name of the subnet where the Application Gateway is deployed.')
param appGatewaySubnetName string = 'subnet-appgateway'

@description('Services Subnet Name. The name of the subnet where the BackEnd services are deployed.')
param servicesSubnetName string = 'subnet-services'

resource appGateway 'Microsoft.Network/applicationGateways@2024-05-01' existing = {
  name: appGatewayName
}

resource appGatewaySubnet 'Microsoft.Network/virtualNetworks/subnets@2024-05-01' existing = {
  name: appGatewaySubnetName
}

resource servicesSubnet 'Microsoft.Network/virtualNetworks/subnets@2024-05-01' existing = {
  name: servicesSubnetName
}

resource kubeletIdentityContributorRoleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(kubeletIdentityClientId, appGateway.id, 'Contributor')
  scope: appGateway
  properties: {
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', 'b24988ac-6180-42a0-ab88-20f7382dd24c') // Contributor
    principalId: kubeletIdentityObjectId
    principalType: 'ServicePrincipal'
  }
}

resource kubeletIdentityNetworkContributorRoleAssignmentToAGSubnet 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(kubeletIdentityClientId, appGatewaySubnet.id, 'Network Contributor')
  scope: appGatewaySubnet
  properties: {
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', '4d97b98b-1d4f-4787-a291-c67834d212e7') // Network Contributor
    principalId: kubeletIdentityObjectId
    principalType: 'ServicePrincipal'
  }
}

resource kubeletIdentityNetworkContributorRoleAssignmentToServicesSubnet 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(kubeletIdentityClientId, servicesSubnet.id, 'Network Contributor')
  scope: servicesSubnet
  properties: {
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', '4d97b98b-1d4f-4787-a291-c67834d212e7') // Network Contributor
    principalId: kubeletIdentityObjectId
    principalType: 'ServicePrincipal'
  }
}
