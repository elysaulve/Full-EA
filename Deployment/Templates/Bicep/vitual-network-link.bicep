// ========== Virtual Network Link ========== //

@description('AKS VNet Name. The name of the AKS Virtual Network'.)
param aksName string

@description('End Resource Name. The name of the resource to link the AKS VNet to the private DNS zone.')
param endResourceName string

@description('Private DNS Zone Name. The name of the private DNS zone to be used for the private endpoint.')
param privateDnsZoneName string = 'privatelink.blob.${environment().suffixes.storage}'

@description('Id of the AKS virtual network')
param aksVnetId string

resource privateDnsZone 'Microsoft.Network/privateDnsZones@2024-06-01' existing = {
  name: privateDnsZoneName
}

// Virtual Network Link to DNS Zone
resource vnetLink 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2024-06-01' = {
  name: '${aksName}To${endResourceName}-link'
  parent: privateDnsZone
  location: 'global'
  properties: {
    virtualNetwork: {
      id: aksVnetId
    }
    registrationEnabled: false
  }
}
