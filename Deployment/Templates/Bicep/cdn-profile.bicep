//---------- CDN Profile ----------//
@minLength(3)
@maxLength(15)
@description('Solution Name')
param solutionName string

@description('Solution Location')
param solutionLocation string = resourceGroup().location

@description('CDN Profile Name')
param cdnProfileName string = '${ solutionName }cdnp'

@description('User Assigned Identities. Gets or sets a list of key value pairs that describe the set of User Assigned identities that will be used with this storage account.')
param userAssignedIdentity string

@description('Managed Identity Type. ')
@allowed([
  'None'
  'SystemAssigned'
  'UserAssigned'
])
param identityType string = 'UserAssigned'

@description('Name of the CDN Endpoint, must be unique')
param cdnEndpointName string = '${ solutionName }cdnpep'

@description('Url of the origin')
param originUrls array = [ 'dev.${ solutionName }.com', '${ solutionName }.com' ]

@description('SKU. The pricing tier (defines Azure Front Door Standard or Premium or a CDN provider, feature list and rate) of the profile.')
@allowed([
  'Custom_Verizon'
  'Premium_AzureFrontDoor'
  'Premium_Verizon'
  'StandardPlus_955BandWidth_ChinaCdn'
  'StandardPlus_AvgBandWidth_ChinaCdn'
  'StandardPlus_ChinaCdn'
  'Standard_955BandWidth_ChinaCdn'
  'Standard_Akamai'
  'Standard_AvgBandWidth_ChinaCdn'
  'Standard_AzureFrontDoor'
  'Standard_ChinaCdn'
  'Standard_Microsoft'
  'Standard_Verizon'
])

param sku string = 'Standard_Microsoft'

resource cdnProfile 'Microsoft.Cdn/profiles@2023-07-01-preview' = {
  name: cdnProfileName
  location: solutionLocation
  identity: {
    type: identityType
    userAssignedIdentities: {
      '${userAssignedIdentity}' : {}
    }
  }
  tags: {
    app: solutionName
    location: solutionLocation
  }
  sku: {
    name: sku
  }  
}

resource cdnProfileEndpoint 'Microsoft.Cdn/profiles/endpoints@2023-07-01-preview' = {
  parent: cdnProfile
  name: cdnEndpointName
  location: solutionLocation  
  properties: {
    originHostHeader: originUrls[1]
    isCompressionEnabled: true
    isHttpAllowed: true
    isHttpsAllowed: true
    queryStringCachingBehavior: 'IgnoreQueryString'
    /*defaultOriginGroup: {
      id: cdnProfileOriginGroups.id
    }*/    
    contentTypesToCompress: [
      'application/eot'
      'application/font'
      'application/font-sfnt'
      'application/javascript'
      'application/json'
      'application/opentype'
      'application/otf'
      'application/pkcs7-mime'
      'application/truetype'
      'application/ttf'
      'application/vnd.ms-fontobject'
      'application/xhtml+xml'
      'application/xml'
      'application/xml+rss'
      'application/x-font-opentype'
      'application/x-font-truetype'
      'application/x-font-ttf'
      'application/x-httpd-cgi'
      'application/x-javascript'
      'application/x-mpegurl'
      'application/x-opentype'
      'application/x-otf'
      'application/x-perl'
      'application/x-ttf'
      'font/eot'
      'font/ttf'
      'font/otf'
      'font/opentype'
      'image/svg+xml'
      'text/css'
      'text/csv'
      'text/html'
      'text/javascript'
      'text/js'
      'text/plain'
      'text/richtext'
      'text/tab-separated-values'
      'text/xml'
      'text/x-script'
      'text/x-component'
      'text/x-java-source'
    ]
    origins: [
      {
        name: '${ solutionName }cdnpodev'
        properties: {
          hostName: originUrls[0]
          httpPort: 80
          httpsPort: 443
          originHostHeader: originUrls[0]
        }
      }     
    ]    
  }
}

/*var cdnpodev = '${ cdnProfileName }/${ cdnEndpointName }/${ solutionName }cdnpodev'

resource cdnProfileOriginDev 'Microsoft.Cdn/profiles/endpoints/origins@2023-07-01-preview' = {
  name: cdnpodev
  properties: {
    hostName: 'dev.${ solutionName }.com'
    originHostHeader: 'dev.${ solutionName }.com'
    priority: 1
    weight: 1000
    enabled: true    
    httpPort: 80
    httpsPort: 443
  }  
}

var cdnpo = '${ cdnProfileName }/${ cdnEndpointName }/${ solutionName }cdnpo'

resource cdnProfileOrigin 'Microsoft.Cdn/profiles/endpoints/origins@2023-07-01-preview' = {
  name: cdnpo
  properties: {
    hostName: '${ solutionName }.com'
    originHostHeader: '${ solutionName }.com'
    priority: 1
    weight: 1000
    enabled: true
    httpPort: 80
    httpsPort: 443
  } 
}

var cdnpogName = '${ solutionName }cdnpog'

resource cdnProfileOriginGroups 'Microsoft.Cdn/profiles/endpoints/originGroups@2022-11-01-preview' = {
  name: cdnpogName
  properties: {
    healthProbeSettings: {
      probePath: '/healthprobe'
      probeRequestType: 'HEAD'
      probeProtocol: 'Http'
      probeIntervalInSeconds: 240
    }
    origins: [
      
    ]      
  }
}
*/
