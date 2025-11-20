// ========== NAT Gateway ========== //
targetScope = 'resourceGroup'

@minLength(3)
@maxLength(15)
@description('Solution Name')
param solutionName string

@description('Solution Location')
param solutionLocation string = resourceGroup().location

@description('Name')
param ngName string = '${ solutionName }-ng'

@description('SKU Name. The nat gateway SKU.')
param skuName string = 'Standard'

@description('Idle Timeout In Minutes. The idle timeout of the public IP address.')
param idleTimeoutInMinutes int = 5

@description('Public IP Address Id. An array of public ip addresses associated with the nat gateway resource.')
param publicIpAddressId string = ''

resource natGateway 'Microsoft.Network/natGateways@2024-05-01' = {
  name: ngName
  location: solutionLocation
  sku: {
    name: skuName
  }
  properties: {
    idleTimeoutInMinutes: idleTimeoutInMinutes
    publicIpAddresses: [
      {
        id: publicIpAddressId
      }
    ]
  }
}

output natGatewayOutput object = {
  id: natGateway.id
  name: ngName
}
