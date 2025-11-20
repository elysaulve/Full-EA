// ========== Application Gateway ========== //
targetScope = 'resourceGroup'

@description('The name of the Managed Cluster resource.')
param solutionName string = ''

@description('The location of the Managed Cluster resource.')
param solutionLocation string = resourceGroup().location

@description('App Gateway Name. The name of the Application Gateway resource.')
param agName string = '${ solutionName }-ag'

@description('Managed Identity ID. The resource ID of the user assigned identity to be used for the application gateway deployment.')
param managedIdentityId string

@description('Managed Identity Principal Id. The principal ID of the user assigned identity to be used for the application gateway deployment.')
param managedIdentityPrincipalId string 

@allowed([
  'Generation_1'
  'Generation_2'
])
@description('SKU Family. Family of an application gateway SKU.')
param skuFamily string = 'Generation_2'

@allowed([
  'Basic'
  'Standard_Large'
  'Standard_Medium'
  'Standard_Small'
  'Standard_v2'
  'WAF_Large'
  'WAF_Medium'
  'WAF_v2'
])
@description('SKU Name. Name of an application gateway SKU.')
param skuName string = 'WAF_v2'

@allowed([
  'Basic'
  'Standard'
  'Standard_v2'
  'WAF'
  'WAF_v2'
])
@description('SKU Tier. Tier of an application gateway.')
param skuTier string = 'WAF_v2'

@description('Max Capacity. Upper bound on number of Application Gateway capacity.')
param maxCapacity int = 3

@description('Min Capacity. Lower bound on number of Application Gateway capacity.')
param minCapacity int = 1

@description('public IP Address. The resource ID of the public IP address to be associated with the application gateway.')
param publicIpAddress string = ''

@description('App Gateway Subnet Id. The resource ID of the subnet to deploy the application gateway into.')
param appGatewaySubnetId string = ''

@description('Drain Timeout In Sec. The number of seconds connection draining is active. Acceptable values are from 1 second to 3600 seconds.')
param drainTimeoutInSec int = 60

@description('Connection Draining. Whether connection draining is enabled.')
param connectionDraining bool = true

@description('Request Timeout. Request timeout in seconds. Application Gateway will fail the request if response is not received within RequestTimeout. Acceptable values are from 1 second to 86400 seconds.')
param requestTimeout int = 300

@description('Enable FIPS. Whether FIPS is enabled on the application gateway resource.')
param enableFips bool = false

@description('Enable HTTP2. Whether HTTP2 is enabled on the application gateway resource.')
param enableHttp2 bool = true

@description('Enable Request Buffering. Enable or disable request buffering.')
param enableRequestBuffering bool = true

@description('Enable Response Buffering. Enable or disable response buffering.')
param enableResponseBuffering bool = true

@description('Probe Enabled. Wheter the probe is enabled, default value is false.')
param probeEnabled bool = false

resource wafPolicy 'Microsoft.Network/ApplicationGatewayWebApplicationFirewallPolicies@2024-05-01' = {
  name: 'appGatewayWafPolicy'
  location: solutionLocation
  properties: {    
    customRules: [
      {
        name: 'BlockIPRule'
        priority: 1
        ruleType: 'MatchRule'
        matchConditions: [
          {
            matchVariables: [
              {
                variableName: 'RemoteAddr'
              }
            ]
            operator: 'IPMatch'
            matchValues: [
              '192.168.1.1'
            ]
         }
        ] 
        action: 'Block'
        state: 'Enabled'
      } 
    ]
    managedRules: {
      managedRuleSets: [
        {
          ruleSetType: 'OWASP'
          ruleSetVersion: '3.1'
        }
      ]
    }
    policySettings: {
      fileUploadLimitInMb: 32
      fileUploadEnforcement: true
      state: 'Enabled'
      mode: 'Prevention'
      requestBodyCheck: true
      requestBodyEnforcement: true
      requestBodyInspectLimitInKB: 16
      maxRequestBodySizeInKb: 32
      jsChallengeCookieExpirationInMins: 5
    }
  }
}

resource appGateway 'Microsoft.Network/applicationGateways@2024-07-01' = {
  name: agName
  location: solutionLocation  
  tags: {
    app: solutionName
    location: solutionLocation
  }
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
      family: skuFamily
    }
    autoscaleConfiguration: {
      maxCapacity: maxCapacity
      minCapacity: minCapacity
    }
    gatewayIPConfigurations: [
      {
        name: 'appGatewayIpAddress'
        properties: {
          subnet: {
            id: appGatewaySubnetId
          }
        }
      }
    ]
    frontendIPConfigurations: [
      {
        name: 'appGatewayFrontEndIp'
        properties: {
          privateIPAllocationMethod: 'Dynamic'
          publicIPAddress: {
            id: publicIpAddress
          }
        }
      }
    ]
    frontendPorts: [
      {
        name: 'AppGatewayFrontEndHttpPort'
        properties: {
          port: 80
        }
      }
      {
        name: 'AppGatewayFrontEndHttpsPort'
        properties: {
          port: 443
        }
      }
    ]
    backendAddressPools: [
      {
        name: 'appGatewayBackendAddressPools'        
        properties: {
          backendAddresses: [
          ]
        }
      }
    ]
    backendHttpSettingsCollection: [
      {
        name: 'appGatewayBackendHttpSettings'
        properties: {
          affinityCookieName: 'appGatewayAffinityCookie'
          connectionDraining: {
            drainTimeoutInSec: drainTimeoutInSec
            enabled: connectionDraining
          }
          cookieBasedAffinity: 'Enabled'
          hostName: '${solutionName}.com'
          port: 8080
          probeEnabled: probeEnabled
          protocol: 'Http'
          requestTimeout: requestTimeout
        }
      }
      {
        name: 'appGatewayBackendHttpsSettings'
        properties: {
          affinityCookieName: 'appGatewayAffinityCookie'
          connectionDraining: {
            drainTimeoutInSec: drainTimeoutInSec
            enabled: connectionDraining
          }
          cookieBasedAffinity: 'Enabled'
          hostName: '${solutionName}.com'
          port: 443
          probeEnabled: probeEnabled
          protocol: 'Https'
          requestTimeout: requestTimeout
        }
      }
    ]
    enableFips: enableFips
    enableHttp2: enableHttp2
    globalConfiguration: {
      enableRequestBuffering: enableRequestBuffering
      enableResponseBuffering: enableResponseBuffering
    }
    httpListeners: [
      {
        name: 'appGatewayHttpListener'
        properties: {
          firewallPolicy: {
            id: wafPolicy.id
          }
          frontendIPConfiguration: {
            id: resourceId('Microsoft.Network/applicationGateways/frontendIPConfigurations', agName, 'appGatewayFrontEndIp')
          }
          frontendPort: {
            id: resourceId('Microsoft.Network/applicationGateways/frontendPorts', agName, 'appGatewayFrontEndHttpPort')
          }        
          protocol: 'Http'
          hostNames: [ 
            '${solutionName}.com'
          ]
          requireServerNameIndication: false         
        }
      }      
    ]
    requestRoutingRules: [
      {
        name: 'appGatewayHttpRoutingRules'
        properties: {
          priority: 19500
          ruleType: 'Basic'
          httpListener: {
            id: resourceId('Microsoft.Network/applicationGateways/HttpListeners', agName, 'appGatewayHttpListener')
          }   
          backendAddressPool: {
            id: resourceId('Microsoft.Network/applicationGateways/backendAddressPools', agName, 'appGatewayBackendAddressPools')
          }
          backendHttpSettings: {
            id: resourceId('Microsoft.Network/applicationGateways/backendHttpSettingsCollection', agName, 'appGatewayBackendHttpSettings')
          }                 
        }
      }
    ]
    probes: [
      {
        name: 'appGatewayProbes'
        properties: {
          protocol: 'Http'
          host: 'localhost'
          path: '/'
          interval: 30
          timeout: 30
          unhealthyThreshold: 3
          pickHostNameFromBackendHttpSettings: false
          minServers: 0
          match: {
            body: 'OK'
            statusCodes: [
              '200-399'
            ]
          }
        }
      } 
    ]
    firewallPolicy: {
      id: wafPolicy.id
    }
    rewriteRuleSets: []
    redirectConfigurations: []
    privateLinkConfigurations: []
  }
}

output appGatewayOutput object = {
  id: appGateway.id
  name: agName
}
