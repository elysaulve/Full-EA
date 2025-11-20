// ========== Virtual Network ========== //
targetScope = 'resourceGroup'

@minLength(3)
@maxLength(15)
@description('Solution Name')
param solutionName string

@description('Solution Location')
param solutionLocation string = resourceGroup().location

@description('Name')
param vnName string = '${ solutionName }-vn'

@description('Flow Timeout in Minutes. The FlowTimeout value (in minutes) for the Virtual Network.')
param flowTimeoutInMinutes int = 5

@description('NSG Flush Connection. When enabled, flows created from Network Security Group connections will be re-evaluated when rules are updates. Initial enablement will trigger re-evaluation.')
param nsgFlushConnection bool = false

@description('NAT Gateway ID. ')
param natGatewayId string

resource networkSecurityGroupAppGateway 'Microsoft.Network/networkSecurityGroups@2024-07-01' = {  
  name: 'appgateway-nsg'
  location: solutionLocation
  tags: {
    app: solutionName
    location: solutionLocation
  }
  properties: {
    securityRules: [    
    ]
    flushConnection: nsgFlushConnection
  }
}

resource networkSecurityGroupServices 'Microsoft.Network/networkSecurityGroups@2024-07-01' = {  
  name: 'services-nsg'
  location: solutionLocation
  tags: {
    app: solutionName
    location: solutionLocation
  }
  properties: {
    securityRules: [
    ]
    flushConnection: nsgFlushConnection
  }
}

resource networkSecurityGroupDatabricksPrivate 'Microsoft.Network/networkSecurityGroups@2024-07-01' = {  
  name: 'databricks-private-nsg'
  location: solutionLocation
  tags: {
    app: solutionName
    location: solutionLocation
  }
  properties: {
    securityRules: [
    ]
    flushConnection: nsgFlushConnection
  }
}

resource networkSecurityGroupDatabricksPublic 'Microsoft.Network/networkSecurityGroups@2024-07-01' = {  
  name: 'databricks-public-nsg'
  location: solutionLocation
  tags: {
    app: solutionName
    location: solutionLocation
  }
  properties: {
    securityRules: [
    ]
    flushConnection: nsgFlushConnection
  }
}

resource networkSecurityGroupVirtualNetworkGateway 'Microsoft.Network/networkSecurityGroups@2024-07-01' = {  
  name: 'virtual-network-gateway-nsg'
  location: solutionLocation
  tags: {
    app: solutionName
    location: solutionLocation
  }
  properties: {
    securityRules: [
    ]
    flushConnection: nsgFlushConnection
  }
}

resource networkSecurityGroupLocalNetworkGateway 'Microsoft.Network/networkSecurityGroups@2024-07-01' = {  
  name: 'local-network-gateway-nsg'
  location: solutionLocation
  tags: {
    app: solutionName
    location: solutionLocation
  }
  properties: {
    securityRules: [
    ]
    flushConnection: nsgFlushConnection
  }
}

resource networkSecurityGroupNatGateway 'Microsoft.Network/networkSecurityGroups@2024-07-01' = {  
  name: 'natgateway-nsg'
  location: solutionLocation
  tags: {
    app: solutionName
    location: solutionLocation
  }
  properties: {
    securityRules: [
    ]
    flushConnection: nsgFlushConnection
  }
}

resource virtualNetwork 'Microsoft.Network/virtualNetworks@2024-10-01' = {
  location: solutionLocation
  name: vnName
  properties: {
    addressSpace: {
      addressPrefixes: [
        '10.224.0.0/12'                
      ]
    }
    subnets: [
      { 
        name: 'subnet-appgateway'
        properties: {
          addressPrefix: '10.224.0.0/24'
        }
      }
      { 
        name: 'subnet-services'
        properties: {
          addressPrefix: '10.225.0.0/24'
          natGateway: {
            id: natGatewayId
          }
          networkSecurityGroup: {
            id: networkSecurityGroupServices.id
          }
        }
      } 
      { 
        name: 'subnet-databricks-private'
        properties: {
          addressPrefix: '10.226.0.0/16'
          delegations: [
            {
              name: 'subnetDatabricksPublicDelegation'
              properties: {
                serviceName: 'Microsoft.Databricks/workspaces'
              }
            }
          ]
          networkSecurityGroup: {
            id: networkSecurityGroupDatabricksPrivate.id
          }
        }
      }
      {
        name: 'subnet-databricks-public'
        properties: {
          addressPrefix: '10.227.0.0/16'
          delegations: [
            {
              name: 'subnetDatabricksPublicDelegation'
              properties: {
                serviceName: 'Microsoft.Databricks/workspaces'
              }
            }
          ]
          networkSecurityGroup: {
            id: networkSecurityGroupDatabricksPublic.id
          }
        }
      }
      {
        //Microsoft requires this exact name for the subnet
        name: 'GatewaySubnet'
        properties: {
          addressPrefix: '10.230.0.0/16'         
        }
      }
      {
        name: 'subnet-localnetworkgateway'
        properties: {
          addressPrefix: '10.231.0.0/16'
          networkSecurityGroup: {
            id: networkSecurityGroupLocalNetworkGateway.id 
          } 
        }
      }
      {
        name: 'subnet-natgateway'
        properties: {
          addressPrefix: '10.239.0.0/16'
          networkSecurityGroup: {
            id: networkSecurityGroupNatGateway.id 
          }
        }
      }  
    ]
    flowTimeoutInMinutes: flowTimeoutInMinutes
  }
}

output virtualNetworkOutput object = {
  id: virtualNetwork.id
  name: vnName
  appGatewaySubnet: {
    id: virtualNetwork.properties.subnets[0].id
    name: virtualNetwork.properties.subnets[0].name
    addressPrefix: virtualNetwork.properties.subnets[0].properties.addressPrefix
  }
  servicesSubnet: {
    id: virtualNetwork.properties.subnets[1].id
    name: virtualNetwork.properties.subnets[1].name
    addressPrefix: virtualNetwork.properties.subnets[1].properties.addressPrefix
  }
  databricksSubnetPrivate: {
    id: virtualNetwork.properties.subnets[2].id
    name: virtualNetwork.properties.subnets[2].name
    addressPrefix: virtualNetwork.properties.subnets[2].properties.addressPrefix
  }
  databricksSubnetPublic: {
    id: virtualNetwork.properties.subnets[3].id
    name: virtualNetwork.properties.subnets[3].name
    addressPrefix: virtualNetwork.properties.subnets[3].properties.addressPrefix
  }
  virtualNetworkGatewaySubnet: {
    id: virtualNetwork.properties.subnets[4].id
    name: virtualNetwork.properties.subnets[4].name
    addressPrefix: virtualNetwork.properties.subnets[4].properties.addressPrefix
  }
  localNetworkGatewaySubnet: {
    id: virtualNetwork.properties.subnets[5].id
    name: virtualNetwork.properties.subnets[5].name
    addressPrefix: virtualNetwork.properties.subnets[5].properties.addressPrefix
  }
  natGatewaySubnet: {
    id: virtualNetwork.properties.subnets[6].id
    name: virtualNetwork.properties.subnets[6].name
    addressPrefix: virtualNetwork.properties.subnets[6].properties.addressPrefix
  }
}
