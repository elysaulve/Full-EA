// ========== DNS Zones ========== //
@minLength(3)
@maxLength(15)
@description('Solution Name')
param solutionName string

@description('DNS Zone Name.')
param dnsZonesName string = '${ solutionName }.com'

@description('DNS Zone Type. The type of this DNS zone (Public or Private).')
@allowed([
  'Public'
  'Private'
])
param dnsZonesType string = 'Public'

resource dnsZones 'Microsoft.Network/dnsZones@2023-07-01-preview' = {
  name: dnsZonesName
  location: 'Global'
  tags: {
    app: solutionName
    location: 'Global'
  } 
  properties: {    
    zoneType: dnsZonesType
  }
}

output dnsZonesOutput object = {
  id: dnsZones.id
  name: dnsZones.name  
}
