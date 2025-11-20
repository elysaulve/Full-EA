// ========== Managed Identity ========== //
targetScope = 'resourceGroup'

@minLength(3)
@maxLength(15)
@description('Solution Name')
param solutionName string

@description('Solution Location')
param solutionLocation string

@description('Name')
param miName string = '${ solutionName }-mi'

resource managedIdentity 'Microsoft.ManagedIdentity/userAssignedIdentities@2025-01-31-preview' = {
  name: miName
  location: solutionLocation
  tags: {
    app: solutionName
    location: solutionLocation    
  }  
}

var customRoleName = guid(resourceGroup().id, managedIdentity.id, miName, solutionName)

resource deploymentScriptRoleDefinition 'Microsoft.Authorization/roleDefinitions@2022-05-01-preview'  = {  
  name: customRoleName
  properties: {
    roleName: customRoleName
    assignableScopes: [
      subscription().id
      resourceGroup().id
    ]
    description: 'Configure least privilege for the deployment principal - ${solutionName}'
    type: 'customRole'
    permissions: [
      {
        actions: [
          'Microsoft.ContainerRegistry/registries/pull/read'
          'Microsoft.ContainerService/managedClusters/listClusterAdminCredential/action'
          'Microsoft.ContainerService/managedClusters/accessProfiles/listCredential/action'
          'Microsoft.ContainerService/managedClusters/read'
          'Microsoft.ContainerService/managedClusters/runcommand/action'
          'Microsoft.Storage/StorageAccounts/*'          
          'Microsoft.ContainerInstance/containerGroups/*'
          'Microsoft.Resources/deployments/*'
          'Microsoft.Resources/deploymentScripts/*'
          'Microsoft.Storage/register/action'
          'Microsoft.ContainerInstance/register/action'
        ]
      }
    ]        
  }
}

resource customRoleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(resourceGroup().id, managedIdentity.id, deploymentScriptRoleDefinition.id)
  properties: {
    principalId: managedIdentity.properties.principalId
    roleDefinitionId:  deploymentScriptRoleDefinition.id
    principalType: 'ServicePrincipal' 
  }
}

output managedIdentityOutput object = {
  id: managedIdentity.id
  clientId: managedIdentity.properties.clientId
  objectId: managedIdentity.properties.principalId
  name: miName
}
