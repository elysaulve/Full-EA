// ========== Private End-Point ========== //
targetScope = 'resourceGroup'

@description('The location of the Managed Cluster resource.')
param solutionLocation string = resourceGroup().location

@description('Service Name. The name of the service resource')
param serviceName string

@description('Subnet ID. Id of the subnet for the private endpoint.')
param subnetId string

@description('Resource Name for Private EndPoint. Resource name for the private endpoint.')
param resourceNameForPE string 

@description('Resource Id for Private EndPoint. Resource Id for the private endpoint')
param resourceIdForPE string

@description('Resource Group Ids for Private EndPoint. Resource group ids of the Resource for the private endpoint')
param resourceGroupIdsForPE array = []

var peResourceName = '${serviceName}To${resourceNameForPE}-pe'

// Private Endpoint
resource resourcePrivateEndpoint 'Microsoft.Network/privateEndpoints@2024-10-01' = {
  name: peResourceName
  location: solutionLocation
  properties: {
    subnet: {
      id: subnetId
    }
    privateLinkServiceConnections: [
      {
        name: '${peResourceName}-plsc'
        properties: {
          privateLinkServiceId: resourceIdForPE
          groupIds: resourceGroupIdsForPE
        }
      }
    ]
  }
}

output resourcePrivateEndPointOutput object = {
  id: resourcePrivateEndpoint.id
  name: resourcePrivateEndpoint.name
}
