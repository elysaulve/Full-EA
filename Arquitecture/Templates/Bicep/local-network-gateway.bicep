// ========== Local Network Gateway ========== //
targetScope = 'resourceGroup'

@minLength(3)
@maxLength(15)
@description('Solution Name')
param solutionName string

@description('Solution Location')
param solutionLocation string = resourceGroup().location

@description('Name')
param lngName string = '${ solutionName }-lng'

@description('ASN. Autonomous System Number (ASN) for BGP Peering.')
param asn int = 650100

@description('BGP Peering Address. The BGP peering address of the local network gateway.')
param bgpPeeringAddress string

@description('Peer Weight. The weight added to routes learned from this BGP speaker.')
param peerWeight int = 0

@description('Gateway IP Address. The IP address of the local network gateway.')
param gatewayIpAddress string = ''

@description('Local Network Address Prefix. Prefix for the local network site.')
param localNetworkAddressPrefix string = ''

resource localNetworkGateway 'Microsoft.Network/localNetworkGateways@2024-10-01' = {
  location: solutionLocation
  name: lngName
  tags: {
    app: solutionName
    location: solutionLocation    
  }
  properties: {
    gatewayIpAddress: gatewayIpAddress
    bgpSettings: {
      asn: asn
      bgpPeeringAddress: bgpPeeringAddress
      peerWeight: peerWeight
    }
    localNetworkAddressSpace: {
      addressPrefixes: [
        localNetworkAddressPrefix
      ]
    }
  }
}
