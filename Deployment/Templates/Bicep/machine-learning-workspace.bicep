// ========== Machine Learning Workspace ========== //
@description('Solution Name')
param solutionName string

@description('Solution Location')
param solutionLocation string

@description('ML Workspace Name')
param mlwsName string = '${ solutionName }-mlws'

@description('Managed Identity Id. The Azure resource Id of the managed identity used for the deployment.')
param managedIdentityId string 

@description('Storage Account. ARM id of the storage account associated with this workspace. This cannot be changed once the workspace has been created')
param storageAccount string 

@description('KeyVault. ARM id of the key vault associated with this workspace. This cannot be changed once the workspace has been created')
param keyVault string

@description('Application Insights. ARM id of the application insights associated with this workspace.')
param applicationInsights string

@description('Container Registry. ARM id of the container registry associated with this workspace.')
param containerRegistry string

@description('Public Network Access. Whether requests from Public Network are allowed.')
@allowed([
  'Enabled'
  'Disabled'
])
param publicNetworkAccess string = 'Enabled'

@description('SKU Name. The name of the SKU. Ex - P3. It is typically a letter+number code.')
param skuName string = 'Basic'

@description('SKU Tier. This field is required to be implemented by the Resource Provider if the service has more than one tier, but is not required on a PUT.')
@allowed([
  'Basic'
  'Free'
  'Standard'
  'Premium'
])
param skuTier string = 'Basic'

var discoveryURL = 'https://${ solutionLocation }.api.azureml.ms/discovery'

resource mlwsWorkspace 'Microsoft.MachineLearningServices/workspaces@2025-07-01-preview' = {
  name: mlwsName
  location: solutionLocation
  sku: {
    name: skuName
    tier: skuTier
  } 
  identity: {
    type: 'UserAssigned'
    userAssignedIdentities: {    
      '${ managedIdentityId }' : {}      
    }
  }
  properties: {
    primaryUserAssignedIdentity: managedIdentityId
    friendlyName: mlwsName
    storageAccount: storageAccount
    keyVault: keyVault
    applicationInsights: applicationInsights
    hbiWorkspace: false
    v1LegacyMode: false
    containerRegistry: containerRegistry
    publicNetworkAccess: publicNetworkAccess
    discoveryUrl: discoveryURL
  }
}

output machineLearningWorkspaceOutput object = {
  id: mlwsWorkspace.id
  name: mlwsName  
}
