// ========== Log Analytics Workspace ========== //
targetScope = 'resourceGroup'

@minLength(3)
@maxLength(15)
@description('Solution Name')
param solutionName string

@description('Solution Location')
param solutionLocation string

@description('Log Analytics Workspace Name')
param lawsName string = '${ solutionName }-laws'

@description('Managed Identity Type. ')
@allowed([
  'None'
  'SystemAssigned'
  'UserAssigned'
])
param identityType string = 'UserAssigned'

@description('SKU Name. The name of the SKU.')
@allowed([
  'CapacityReservation'
  'Free'
  'LACluster'
  'PerGB2018'
  'PerNode'
  'Premium'
  'Standalone'
  'Standard'
])
param skuName string = 'PerGB2018'

@description('Managed Identity Id. Resource identifier of the UserAssigned identity to be used for the Log Analytics Workspace.')
param managedIdentityId string

resource logAnalyticsWorkspace 'Microsoft.OperationalInsights/workspaces@2023-09-01' = {
  name: lawsName
  location: solutionLocation
  tags: {
    app: solutionName
    location: solutionLocation
  }
  identity: {
    type: identityType
    userAssignedIdentities: {
      '${managedIdentityId}' : {}
    }
  }
  properties: {
    sku: {
      name: skuName
    }
    retentionInDays: 90
    workspaceCapping: {
      dailyQuotaGb: json('0.025')
    }
  }
}

var key = logAnalyticsWorkspace.listKeys().primarySharedKey

output logAnalyticsWorkspaceOutput object = {
  id: logAnalyticsWorkspace.id
  name: lawsName
  workspaceId: logAnalyticsWorkspace.properties.customerId
  workspaceKey: key
}
