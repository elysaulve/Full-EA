// ========== Public IP Address ========== //
targetScope = 'resourceGroup'

@minLength(3)
@maxLength(15)
@description('Solution Name')
param solutionName string

@description('Solution Location')
param solutionLocation string = resourceGroup().location

@description('Name')
param pipName string = '${ solutionName }-pip'

@allowed([
  'Basic'
  'Standard'
])
@description('SKU Name. Name of a public IP address SKU.')
param skuName string = 'Standard'

@allowed([
  'Global'
  'Regional'
])
@description('SKU Tier. Tier of a public IP address SKU.')
param skuTier string = 'Regional'

@allowed([
  'Delete'
  'Detach'
])
@description('Delete Option. Specify what happens to the public IP address when the VM using it is deleted')
param deleteOption string = 'Detach'

@description('Domain Name Label. The concatenation of the domain name label and the regionalized DNS zone make up the fully qualified domain name associated with the public IP address. If a domain name label is specified, an A DNS record is created for the public IP in the Microsoft Azure DNS system.')
param domainNameLabel string = ''

@allowed([
  'FirstPartyUsage'
  'NetworkDomain'
  'RoutingPreference'
])
@description('IP Tag Type.')
param ipTagType string = 'NetworkDomain'

@allowed([
  'NoReuse'
  'ResourceGroupReuse'
  'SubscriptionReuse'
  'TenantReuse'
])
@description('Domain Name Label Scope. If a domain name label and a domain name label scope are specified, an A DNS record is created for the public IP in the Microsoft Azure DNS system with a hashed value includes in FQDN.')
param domainNameLabelScope string = 'NoReuse'

@description('Idle Timeout In Minutes. The idle timeout of the public IP address.')
param idleTimeoutInMinutes int = 5

@allowed([
  'IPv4'
  'IPv6'
])
@description('Public IP Address Version. The public IP address version.')
param publicIPAddressVersion string = 'IPv4'

@allowed([
  'Dynamic'
  'Static'
])
@description('Public IP Allocation Method. The public IP address allocation method.')
param publicIPAllocationMethod string = 'Static'

var pointIndex = indexOf(domainNameLabel, '.')
var domainName = substring(domainNameLabel, 0, pointIndex)

resource publicIpAddress 'Microsoft.Network/publicIPAddresses@2025-01-01' = {
  location: solutionLocation
  name: pipName
  sku: {
    name: skuName
    tier: skuTier
  }
  tags: {
    app: solutionName
    location: solutionLocation
  }
  zones: [
    '1'
    '2'
  ]
  properties: {    
    publicIPAddressVersion: publicIPAddressVersion
    publicIPAllocationMethod: publicIPAllocationMethod
    deleteOption: deleteOption
    idleTimeoutInMinutes: idleTimeoutInMinutes   
    dnsSettings: {
      domainNameLabel: domainName
      domainNameLabelScope: domainNameLabelScope     
    }
    ipTags: [
      {
        ipTagType: ipTagType
        tag: solutionName
      }
    ]
  } 
}

output publicIpAddressOutput object = {
  id: publicIpAddress.id
  name: pipName
}

