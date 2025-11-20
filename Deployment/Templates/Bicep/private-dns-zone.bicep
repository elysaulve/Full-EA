@description('Solution Name. Solution Name Prefix to be used for all resources.')
param solutionName string

@description('Private End-Point Name. The name of the private endpoint to be used.')
param privateEndPointName string

@description('Private DNS Zone Name. The name of the private DNS zone to be used for the private endpoint.')
param privateDNSZoneName string

// Private DNS Zone for Resource (optional, but recommended)
resource privateDnsZone 'Microsoft.Network/privateDnsZones@2024-06-01' = {
  name: privateDNSZoneName 
  location: 'global'
}

resource resourcePrivateEndpoint 'Microsoft.Network/privateEndpoints@2024-10-01' existing = {
  name: privateEndPointName
}

// DNS Zone Group for Private Endpoint
resource dnsZoneGroup 'Microsoft.Network/privateEndpoints/privateDnsZoneGroups@2024-10-01' = {
  name: 'default'
  parent: resourcePrivateEndpoint
  properties: {
    privateDnsZoneConfigs: [
      {
        name: '${solutionName}Config'
        properties: {
          privateDnsZoneId: privateDnsZone.id
        }
      }
    ]
  }
}

output privateDnsZoneOutput object = {
  id: privateDnsZone.id
  name: privateDnsZone.name
}
