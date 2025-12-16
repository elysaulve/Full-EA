// ========== Container Registry ========== //
targetScope = 'resourceGroup'

@minLength(3)
@maxLength(15)
@description('Solution Name')
param solutionName string

@description('Solution Location')
param solutionLocation string = resourceGroup().location

@description('Name')
param crName string = '${ solutionName }cr'

@description('SKU')
@allowed([
  'Basic'
  'Standard'
  'Premium'
])
param sku string = 'Premium'

@description('Managed Identity Type. ')
@allowed([
  'None'
  'SystemAssigned'
  'UserAssigned'
])
param identityType string = 'UserAssigned'

@description('Managed Identity ID. The resource identifier of the UserAssigned identity to be used for the container registry deployment.')
param managedIdentityId string

@description('Managed Identity Principal ID. The principal id of the UserAssigned identity to be used for the container registry deployment.')
param managedIdentityPrincipalId string

@description('Admin User Enabled. The value that indicates whether the admin user is enabled.')
param adminUserEnabled bool = false

@description('Anonymous Pull Enabled')
param anonymousPullEnabled bool = false

@description('Data EndPoint Enabled. Enables registry-wide pull from unauthenticated clients.')
param dataEndPointEnabled bool = false

@description('Key Vault Identity. The client id of the identity which will be used to access key vault.')
param keyVaultIdentity string = ''

@description('Key Vault Key Identifier. Key vault uri to access the encryption key.')
param keyVaultKeyIdentifier string = ''

@description('Key Vault Status. Indicates whether or not the encryption is enabled for container registry.')
@allowed([
  'Enabled'
  'Disabled'
])
param keyVaultStatus string = 'Disabled' 

@description('ARM Audience Token Policy Status. The policy for using ARM audience token for a container registry. Status is the value that indicates whether the policy is enabled or not.')
@allowed([
  'Enabled'
  'Disabled'
])
param armAudienceTokenPolicyStatus string = 'Enabled'

@description('Export Policy Status. The export policy for a container registry.	Status is the value that indicates whether the policy is enabled or not.')
@allowed([
  'Enabled'
  'Disabled'
])
param exportPolicyStatus string = 'Enabled'

@description('Quarantine Policy Status. The quarantine policy for a container registry. Status is the value that indicates whether the policy is enabled or not.')
@allowed([
  'Enabled'
  'Disabled'
])
param quarantinePolicyStatus string = 'Disabled'

@description('Retetion Policy Status. The retention policy for a container registry. Status is the value that indicates whether the policy is enabled or not.')
@allowed([
  'Enabled'
  'Disabled'
])
param retentionPolicyStatus string = 'Disabled'

@description('Retetion Policy Datys. The retention policy for a container registry. Days is the number of days to retain an untagged manifest after which it gets purged.')
param retentionPolicyDays int = 30

@description('Trust Policy Status. The soft delete policy for a container registry. Status is the value that indicates whether the policy is enabled or not.')
@allowed([
  'Enabled'
  'Disabled'
])
param trustPolicyStatus string = 'Disabled'

@description('Trust Policy Type. The content trust policy for a container registry. The type of trust policy.')
param trustPolicyType string = 'Notary'

@description('Public Network Access. Whether or not public network access is allowed for the container registry.')
@allowed([
  'Enabled'
  'Disabled'
])
param publicNetworkAccess string = 'Enabled'

@description('Zone Redundancy. Whether or not zone redundancy is enabled for this container registry.')
@allowed([
  'Enabled'
  'Disabled'
])
param zoneRedundancy string = 'Disabled'

resource containerRegistry 'Microsoft.ContainerRegistry/registries@2025-11-01' = {
  name: crName
  location: solutionLocation
  tags: {
    app: solutionName
    location: solutionLocation
  }
  sku: {
    name: sku
  }
  identity: {
    type: identityType   
    userAssignedIdentities: {
      '${managedIdentityId}' : {}
    }
  }
  properties: {
    adminUserEnabled: adminUserEnabled
    anonymousPullEnabled: anonymousPullEnabled
    dataEndpointEnabled: dataEndPointEnabled
    encryption: {
      keyVaultProperties: {
        identity: keyVaultIdentity
        keyIdentifier: keyVaultKeyIdentifier
      }
      status: keyVaultStatus
    }
    policies: {
      azureADAuthenticationAsArmPolicy: {
        status: armAudienceTokenPolicyStatus
      }
      exportPolicy: {
        status: exportPolicyStatus
      }
      quarantinePolicy: {
        status: quarantinePolicyStatus
      }
      retentionPolicy: {
        days: retentionPolicyDays
        status: retentionPolicyStatus
      }
      trustPolicy: {
        status: trustPolicyStatus
        type: trustPolicyType
      }
    }
    publicNetworkAccess: publicNetworkAccess
    zoneRedundancy: zoneRedundancy
  }
}

resource acrPullRoleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(containerRegistry.id, managedIdentityPrincipalId, 'AcrPull')
  scope: containerRegistry
  properties: {
    principalId: managedIdentityPrincipalId
    roleDefinitionId:  subscriptionResourceId('Microsoft.Authorization/roleDefinitions', '7f951dda-4ed3-4680-a7ca-43fe172d538d')
    principalType: 'ServicePrincipal' 
  }
}

output containerRegistryOutput object = {
  id: containerRegistry.id
  name: containerRegistry.name
}
