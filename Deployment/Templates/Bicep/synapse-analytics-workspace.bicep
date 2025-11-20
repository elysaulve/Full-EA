// ========== Synapse Analytics Workspace ========== //
@description('Solution Name')
param solutionName string

@description('Solution Location')
param solutionLocation string = resourceGroup().location

@description('Name')
var sawsName = '${ solutionName }-saws'

@description('Data Lake Storage Account URL.')
param dlsAccountUrl string = ''

@description('Data Lake Storage File System.')
param dlsFileSystem string = ''

@description('Data Lake Storage Resource Id. ARM resource Id of this storage account')
param dlsResourceId string

@description('Managed Identity ID. The Azure resource Id of the managed identity used for the deployment.')
param managedIdentityId string

resource synapseAnalyticsWorkspace 'Microsoft.Synapse/workspaces@2021-06-01' = {
  name: sawsName
  location: solutionLocation
  identity: {
    type: 'SystemAssigned,UserAssigned'
    userAssignedIdentities: {
      '${ managedIdentityId }' : {}
    }
  }
  properties: {
    defaultDataLakeStorage: {
      resourceId: dlsResourceId
      createManagedPrivateEndpoint: false
      accountUrl: dlsAccountUrl
      filesystem: dlsFileSystem
    }
    encryption: {
    }
    sqlAdministratorLogin: 'sqladminuser'
    privateEndpointConnections: []
    publicNetworkAccess: 'Enabled'
    azureADOnlyAuthentication: false
    trustedServiceBypassEnabled: true

  }
}

resource Microsoft_Synapse_workspaces_azureADOnlyAuthentications_workspaces_default 'Microsoft.Synapse/workspaces/azureADOnlyAuthentications@2021-06-01' = {
  parent: synapseAnalyticsWorkspace
  name: 'default'
  properties: {
    azureADOnlyAuthentication: false
  }
}

resource workspaces_sparkpoolforml 'Microsoft.Synapse/workspaces/bigDataPools@2021-06-01' = {
  parent: synapseAnalyticsWorkspace
  name: 'sparkpoolforml'
  location: solutionLocation
  properties: {
    sparkVersion: '3.5'
    nodeCount: 10
    nodeSize: 'Medium'
    nodeSizeFamily: 'MemoryOptimized'
    autoScale: {
      enabled: true
      minNodeCount: 3
      maxNodeCount: 10
    }
    autoPause: {
      enabled: true
      delayInMinutes: 15
    }
    isComputeIsolationEnabled: false
    sessionLevelPackagesEnabled: false
    dynamicExecutorAllocation: {
      enabled: false
    }
    isAutotuneEnabled: false
    provisioningState: 'Succeeded'
  }
}

resource Microsoft_Synapse_workspaces_dedicatedSQLminimalTlsSettings_workspaces_default 'Microsoft.Synapse/workspaces/dedicatedSQLminimalTlsSettings@2021-06-01' = {
  parent: synapseAnalyticsWorkspace
  name: 'default'
  properties: {
    minimalTlsVersion: '1.2'
  }
}

resource workspaces_allowAll 'Microsoft.Synapse/workspaces/firewallRules@2021-06-01' = {
  parent: synapseAnalyticsWorkspace
  name: 'allowAll'
  properties: {
    startIpAddress: '0.0.0.0'
    endIpAddress: '255.255.255.255'
  }
}

resource workspaces_allowAllAzure 'Microsoft.Synapse/workspaces/firewallRules@2021-06-01' = {
  name: 'AllowAllWindowsAzureIps'
  parent: synapseAnalyticsWorkspace
  properties: {
    startIpAddress: '0.0.0.0'
    endIpAddress: '0.0.0.0'
  }
}

resource workspaces_AutoResolveIntegrationRuntime 'Microsoft.Synapse/workspaces/integrationruntimes@2021-06-01' = {
  parent: synapseAnalyticsWorkspace
  name: 'AutoResolveIntegrationRuntime'
  properties: {
    type: 'Managed'
    typeProperties: {
      computeProperties: {
        location: 'AutoResolve'
      }
    }
  }
}

output SypnaseAnalyticsWorkspaceOutput object = {
  name: sawsName
  synapseIdentity: '/subscriptions/${subscription().id}/resourceGroups/${resourceGroup().name}/providers/Microsoft.ManagedIdentity/systemAssignedIdentities/${sawsName}'
}



