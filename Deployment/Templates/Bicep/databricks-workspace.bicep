// ========== Databricks Workspace ========== //
targetScope = 'resourceGroup'

@minLength(3)
@maxLength(15)
@description('Solution Name')
param solutionName string

@description('Solution Location')
param solutionLocation string = resourceGroup().location

@description('Managed Identity ID. The Azure resource Id of the managed identity used for the deployment.')
param managedIdentityId string

@description('Managed Identity Principal Id. The principal id of the user assigned identity used for the deployment.')
param managedIdentityPrincipalId string = '' 

@description('The pricing tier of workspace.')
@allowed([
  'Trial'
  'Standard'
  'Premium'
])
param skuTier string = 'Premium'

@allowed([
  'Disabled'
  'Enabled'
])
@description('Default Storage Firewall. Whether to enable the firewall for the default storage account associated with the workspace.')
param defaultStorageFirewall string = 'Enabled'

@description('AML Workspace Id. The Azure resource Id of the Machine Learning workspace to be associated with this Databricks workspace.')
param amlWorkspaceId string = ''

@description('Custom Virtual Network Id. The Azure resource Id of the custom virtual network to be used by the workspace.')
param customVirtualNetworkId string = ''

@description('Custom Private Subnet Name. The name of the custom private subnet in the virtual network to be used by the workspace.')
param customPrivateSubnetName string = ''

@description('Custom Public Subnet Name. The name of the custom public subnet in the virtual network to be used by the workspace.')
param customPublicSubnetName string = ''

@description('Enable No Public Ip. Whether to disable public IP for the workspace.'
)
param enableNoPublicIp bool = true

@allowed([
  'Disabled'
  'Enabled'
])
@description('Public Network Access. Whether or not public endpoint access is allowed for this workspace.')
param publicNetworkAccess string = 'Enabled'

@description('Storage Account Name. The name of the storage account to be associated with this workspace.')
param storageAccountName string  = '${solutionName}dbwssa'

@description('Storage Account SKU. The SKU of the storage account to be associated with this workspace.')
param storageAccountSKU string = 'Standard_LRS'

@description('Encryption Key Vault Uri. The URI of the key vault to be used for encryption at rest with customer-managed keys.')
param keyVaultRef string

@description('Encryption Key Name. The name of the key in Key Vault to be used for encryption at rest with customer-managed keys.') 
param encryptionKeyName string = ''

@description('Encryption Key Version. The version of the key in Key Vault to be used for encryption at rest with customer-managed keys. If not provided, the latest version of the key will be used.')
param encryptionKeyVersion string = ''

@description('Name')
param dbwsName string = '${ solutionName }-dbws'

var dbwsacName = '${ solutionName }-dbwsac'

resource accessConector 'Microsoft.Databricks/accessConnectors@2025-03-01-preview' = {
  name: dbwsacName
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
    
  }
}

var managedResourceGroupId string = '/subscriptions/${subscription().subscriptionId}/resourceGroups/${solutionName}_${solutionLocation}_databricks'

resource databricksWorkspace 'Microsoft.Databricks/workspaces@2025-03-01-preview' = {
  name: dbwsName
  location: solutionLocation
  tags: {
    app: solutionName
    location: solutionLocation
  }
  sku: {
    name: skuTier
  }
  properties: {
    authorizations: [
      {
        principalId: managedIdentityPrincipalId
        roleDefinitionId: '8e3af657-a8ff-443c-a75c-2fe8c4bcb635'
      }
    ]
    managedResourceGroupId: managedResourceGroupId
    publicNetworkAccess: publicNetworkAccess
    requiredNsgRules: 'AllRules'
    defaultStorageFirewall: defaultStorageFirewall    
    defaultCatalog: {
      initialType: 'UnityCatalog'
    }    
    accessConnector: {
      id: accessConector.id
      identityType: 'UserAssigned'
      userAssignedIdentityId: managedIdentityId
    }
    encryption: {
      entities: {
        managedDisk: {
          keySource: 'Microsoft.Keyvault'
          keyVaultProperties: {
            keyVaultUri: keyVaultRef
            keyName: encryptionKeyName
            keyVersion: encryptionKeyVersion
          }
          rotationToLatestKeyVersionEnabled: true
        }
        managedServices: {
          keySource: 'Microsoft.Keyvault'
          keyVaultProperties: {
            keyVaultUri: keyVaultRef
            keyName: encryptionKeyName
            keyVersion: encryptionKeyVersion
          }
        }
      }
    }
    enhancedSecurityCompliance: {
      automaticClusterUpdate: {
        value: 'Enabled'
      }
      enhancedSecurityMonitoring: {
        value: 'Enabled'
      }
      complianceSecurityProfile: {
        complianceStandards: [
          'HITRUST'
          'PCI_DSS'
          'HIPAA'
        ]
        value: 'Enabled'
      }      
    }
    parameters: {
      amlWorkspaceId: {
        value: amlWorkspaceId
      }
      customVirtualNetworkId: {
        value: customVirtualNetworkId
      }
      customPrivateSubnetName: {
        value: customPrivateSubnetName
      }
      customPublicSubnetName: {
        value: customPublicSubnetName
      }      
      enableNoPublicIp: {
        value: enableNoPublicIp
      }    
      prepareEncryption: {
        value: true
      } 
      requireInfrastructureEncryption: {
        value: true
      }
      storageAccountName: {
        value: storageAccountName
      }
      storageAccountSkuName: {
        value: storageAccountSKU
      }
    }
  }
}

output databricksWorkspaceOutput object = {
  id: databricksWorkspace.id
  name: databricksWorkspace.name
  sku: databricksWorkspace.sku
  properties: databricksWorkspace.properties
}
