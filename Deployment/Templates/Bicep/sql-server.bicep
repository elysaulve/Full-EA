//---------- SQL Server ----------//
@minLength(3)
@maxLength(15)
@description('Solution Name')
param solutionName string

@description('Solution Location')
param solutionLocation string = resourceGroup().location

@description('SQL server Name')
param sqlServerName string = '${ solutionName }sql'

@description('Managed Identity Type. ')
@allowed([
  'None'
  'SystemAssigned'
  'UserAssigned'
])
param identityType string = 'UserAssigned'

@description('Managed Identity ID. The resource ID of the user assigned identity to be used for the deployment.')
param managedIdentityId string

@description('Administrator Login. The administrator\'s login name of a server. Can only be specified when the server is being created (and is required for creation).')
param sqlAdminUsername string 

@description('Administrator Login Password. The administrator login password (required for server creation).')
@secure()
param sqlAdminPassword string

@description('Is IP V6 Enabled. Whether or not to enable IPv6 support for this server. Value is optional but if passed in, must be "Enabled" or "Disabled"')
@allowed([
  'Enabled'
  'Disabled'
])
param isIPv6Enabled string = 'Disabled'

@description('Data Encryption Key URI. A CMK URI of the key to use for encryption.')
param dataEncryptionKeyRef string

@description('Minimal TLS Version. Allowed values "None", "1.0", "1.1", "1.2", "1.3"')
param minimalTlsVersion string = '1.2'

@description('Public Network Access. Whether or not public endpoint access is allowed for this server. Value is optional but if passed in, must be "Enabled" or "Disabled" or "SecuredByPerimeter"')
@allowed([
  'Enabled'
  'Disabled'
  'SecuredByPerimeter'
])
param publicNetworkAccess string = 'Enabled'

@description('Restrict Outbound Network Access. Whether or not to restrict outbound network access for this server. Value is optional but if passed in, must be "Enabled" or "Disabled"')
param restrictOutboundNetworkAccess string = 'Disabled'

resource sqlServer 'Microsoft.Sql/servers@2024-11-01-preview' = {
  name: sqlServerName
  location: solutionLocation
  tags: {
    app: solutionName
    location: solutionLocation
  }
  identity: {
    type: identityType
    userAssignedIdentities: {
      '${ managedIdentityId }' : {}
    }
  }
  properties: {
    administratorLogin: sqlAdminUsername
    administratorLoginPassword: sqlAdminPassword
    isIPv6Enabled: isIPv6Enabled
    keyId: dataEncryptionKeyRef
    minimalTlsVersion: minimalTlsVersion
    primaryUserAssignedIdentityId: managedIdentityId
    publicNetworkAccess: publicNetworkAccess
    restrictOutboundNetworkAccess: restrictOutboundNetworkAccess
  } 
}

output sqlServerOutput object = {
  id: sqlServer.id
  name: sqlServer.name
}
