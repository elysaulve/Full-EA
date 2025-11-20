// ========== Virtual Network Gateway ========== //
targetScope = 'resourceGroup'

@minLength(3)
@maxLength(15)
@description('Solution Name')
param solutionName string

@description('Solution Location')
param solutionLocation string = resourceGroup().location

@description('Name')
param vngName string = '${ solutionName }-vng'

@description('Managed Identity ID. The resource ID of the User Assigned Identity to be used for the Virtual Network Gateway deployment.')
param managedIdentityId string

@description('Active Active. Indicates whether the Virtual Network Gateway is active-active.')
param activeActive bool = true

@description('allow remote VNet Traffic. Indicates whether to allow remote VNet traffic.')
param allowremoteVnetTraffic bool = false

@description('allow virtual WAN Traffic. Indicates whether to allow virtual WAN traffic.')
param allowvirtualWanTraffic bool = false

@description('Enable BGP. Indicates whether BGP is enabled for the Virtual Network Gateway.')
param enableBgp bool = false

@description('Enable BGP Route Translation For NAT. Indicates whether BGP route translation for NAT is enabled.')
param enableBgpRouteTranslationForNat bool = false

@description('BGP Peering Address. The BGP peering address of the Virtual Network Gateway.')
param bgpPeeringAddress string = '10.230.0.4,10.230.0.5'

@description('Disable IPSec Replay Protection. Indicates whether to disable IPSec replay protection.')
param disableIPSecReplayProtection bool = false

@description('Enable DNS Forwarding. Indicates whether to enable DNS forwarding.')
param enableDnsForwarding bool = false

@description('Enable High Bandwidth VPN Gateway. Indicates whether to enable high bandwidth VPN gateway.')
param enableHighBandwidthVpnGateway bool = false

@description('Enable Private IP Address. Indicates whether to enable private IP address.')
param enablePrivateIpAddress bool = true

@allowed([
  'Basic'
  'ErGw1AZ'
  'ErGw2AZ'
  'ErGw3AZ'
  'ErGwScale'
  'Alto rendimiento'
  'Standard'
  'Ultra Rendimiento'
  'VpnGw1'
  'VpnGw1AZ'
  'VpnGw2'
  'VpnGw2AZ'
  'VpnGw3'
  'VpnGw3AZ'
  'VpnGw4'
  'VpnGw4AZ'
  'VpnGw5'
  'VpnGw5AZ'
])
param skuName string = 'VpnGw2AZ'

@allowed([
  'Basic'
  'ErGw1AZ'
  'ErGw2AZ'
  'ErGw3AZ'
  'ErGwScale'
  'Alto rendimiento'
  'Standard'
  'Ultra Rendimiento'
  'VpnGw1'
  'VpnGw1AZ'
  'VpnGw2'
  'VpnGw2AZ'
  'VpnGw3'
  'VpnGw3AZ'
  'VpnGw4'
  'VpnGw4AZ'
  'VpnGw5'
  'VpnGw5AZ'
])
param skuTier string = 'VpnGw2AZ'

@allowed([
  'Vpn'
  'LocalGateway'
  'ExpressRoute'
])
@description('Gateway Type. The type of the Virtual Network Gateway.')
param gatewayType string = 'Vpn'

@allowed([
  'None'
  'Generation1'
  'Generation2'
])
param vpnGatewayGeneration string = 'Generation2'

@allowed([
  'RouteBased'
  'PolicyBased'
])
param vpnType string = 'RouteBased'

@description('Virtual Network Gateway Default Public IP ID. The resource ID of the Public IP Address to be used for the Virtual Network Gateway.')
param virtualNetworkGatewayDefaultPublicIpId string

@description('Virtual Network Gateway Active Active Public IP ID. The resource ID of the Public IP Address to be used for the Virtual Network Gateway in active-active mode.')
param virtualNetworkGatewayActiveActivePublicIpId string

@description('Virtual Network Gateway Subnet ID. The resource ID of the Subnet to be used for the Virtual Network Gateway.')
param virtualNetworkGatewaySubnetId string

resource virtualNetworkGateway 'Microsoft.Network/virtualNetworkGateways@2025-01-01' = {
  name: vngName
  location: solutionLocation
  identity: {
    type: 'UserAssigned'
    userAssignedIdentities: {
      '${ managedIdentityId }' : {}
    }
  }
  properties: {
    sku: {
      name: skuName
      tier: skuTier
    }
    gatewayType: gatewayType
    vpnGatewayGeneration: vpnGatewayGeneration
    vpnType: vpnType
    activeActive: activeActive
    adminState: 'string'
    allowRemoteVnetTraffic: allowremoteVnetTraffic
    allowVirtualWanTraffic: allowvirtualWanTraffic
    autoScaleConfiguration: {
      bounds: {
        max: 5
        min: 1
      }
    }
    ipConfigurations: [
      {
        name: 'defaultIpConfig'
        properties: {
          publicIPAddress: {
            id: virtualNetworkGatewayDefaultPublicIpId
          }
          privateIPAllocationMethod: 'Dynamic'
          subnet: {
            id: virtualNetworkGatewaySubnetId
          }
        }
      }
      {
        name: 'activeActiveIpConfig'
        properties: {
          publicIPAddress: {
            id: virtualNetworkGatewayActiveActivePublicIpId
          }
          privateIPAllocationMethod: 'Dynamic'
          subnet: {
            id: virtualNetworkGatewaySubnetId
          }
        }
      }
    ]
    enableBgp: enableBgp
    enableBgpRouteTranslationForNat: enableBgpRouteTranslationForNat
    bgpSettings: {
      asn: 55555
      bgpPeeringAddress: bgpPeeringAddress
      bgpPeeringAddresses: [
        {
          customBgpIpAddresses: [
            '169.254.21.100'
          ]
          ipconfigurationId: resourceId('Microsoft.Network/virtualNetworkGateways/ipConfigurations', vngName, 'defaultIpConfig')
        }
        {
          customBgpIpAddresses: [
            '169.254.21.101'
          ]
          ipconfigurationId: resourceId('Microsoft.Network/virtualNetworkGateways/ipConfigurations', vngName, 'activeActiveIpConfig')
        }
      ]
      peerWeight: 0
    }
    disableIPSecReplayProtection: disableIPSecReplayProtection 
    enableDnsForwarding: enableDnsForwarding
    enableHighBandwidthVpnGateway: enableHighBandwidthVpnGateway
    enablePrivateIpAddress: enablePrivateIpAddress
  }
}

output virtualNetworkGatewayOutput object = {
  id: virtualNetworkGateway.id
  name: virtualNetworkGateway.name
}
