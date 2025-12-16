// ========== Key Vault ========== //
targetScope = 'resourceGroup'

@minLength(3)
@maxLength(15)
@description('Solution Name')
param solutionName string

@description('Solution Location')
param solutionLocation string

@description('Name')
param kvName string = '${ solutionName }-kv'

@description('Create Mode')
param createMode string = 'default'

@description('Enabled For Deployment. Property to specify whether Azure Virtual Machines are permitted to retrieve certificates stored as secrets from the key vault.')
param enableForDeployment bool = true

@description('Enabled For Disk Encryption. Property to specify whether Azure Disk Encryption is permitted to retrieve secrets from the vault and unwrap keys.')
param enableForDiskEncryption bool = true

@description('Enabled For Template Deployment. Property to specify whether Azure Resource Manager is permitted to retrieve secrets from the key vault.')
param enableForTemplateDeployment bool = true

@description('Enable Purge Protection. Property specifying whether protection against purge is enabled for this vault.')
param enablePurgeProtection bool = false

@description('Enable RBAC Authorization. Property that controls how data actions are authorized.')
param enableRBACAuthorization bool = true

@description('Enable Soft Delete. Property to specify whether the "soft delete" functionality is enabled for this key vault.')
param enableSoftDelete bool = false

@description('Soft Delete Retention in Days. softDelete data retention days. It accepts >=7 and <=90.')
param softDeleteRetentionInDays int = 30

@description('Public Network Access, Property to specify whether the vault will accept traffic from public internet.')
@allowed([
  'enabled'
  'disabled'
])
param publicNetworkAccess string = 'enabled'

@description('SKU')
@allowed([
  'standard'
  'premium'
])
param sku string = 'standard'

@description('Tenant Id')
param tenantId string

@description('Vault URI. The URI of the vault for performing operations on keys and secrets.')
var vaultRef = uri('https://${kvName}${environment().suffixes.keyvaultDns}', '/')

@description('Managed Identity Object Id. The object id of the managed identity that will access the Key Vault.')
param managedIdentityPrincipalId string

resource keyVault 'Microsoft.KeyVault/vaults@2025-05-01' = {
  name: kvName
  location: solutionLocation
  tags: {
    app: solutionName
    location: solutionLocation
  }
  properties: {
    accessPolicies: [
      {        
        objectId: managedIdentityPrincipalId        
        permissions: {
          certificates: [
            'all'
          ]
          keys: [
            'all'
          ]
          secrets: [
            'all'
          ]
          storage: [
            'all'
          ]
        }
        tenantId: tenantId
      }
    ]
    createMode: createMode
    enabledForDeployment: enableForDeployment
    enabledForDiskEncryption: enableForDiskEncryption
    enabledForTemplateDeployment: enableForTemplateDeployment
    enablePurgeProtection: enablePurgeProtection
    enableRbacAuthorization: enableRBACAuthorization
    enableSoftDelete: enableSoftDelete
    softDeleteRetentionInDays: softDeleteRetentionInDays
    provisioningState: 'RegisteringDns'
    publicNetworkAccess: publicNetworkAccess
    sku: {
      family: 'A'
      name: sku
    }    
    tenantId: tenantId
    vaultUri: vaultRef
  }
}

@description('This is the built-in Key Vault Administrator role.')
resource kvAdminRole 'Microsoft.Authorization/roleDefinitions@2022-05-01-preview' existing = {
  scope: resourceGroup()
  name: '00482a5a-887f-4fb3-b363-3b7fe8e74483'
}

resource roleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(resourceGroup().id, managedIdentityPrincipalId, kvAdminRole.id)
  properties: {
    principalId: managedIdentityPrincipalId
    roleDefinitionId: kvAdminRole.id
    principalType: 'ServicePrincipal' 
  }
}

@description('Encryption Key Name.')
param encryptionKeyName string = 'encryptionKey'

param expDate int = dateTimeToEpoch(dateTimeAdd(utcNow(), 'P6M'))

resource encryptionKey 'Microsoft.KeyVault/vaults/keys@2025-05-01' = {
  parent: keyVault
  name: encryptionKeyName
  tags: {
    app: solutionName
    location: solutionLocation
  }  
  properties: {
    attributes: {
      enabled: true
      exp: expDate      
    }
    curveName: 'P256-K'
    keyOps: [
      'encrypt'
      'decrypt'     
      'sign'
      'unwrapKey'
      'verify'
      'wrapKey'
    ]
    keySize: 2048
    kty: 'RSA'  
    rotationPolicy: {
      attributes: {
        expiryTime: 'P6M'
      }
      lifetimeActions: [
        {
          action: {
            type: 'rotate'
          }
          trigger: {
            timeAfterCreate: 'P5M'            
          }
        }
      ]
    }     
  }
}

resource managedIdentityKVCryptoServiceEncryptionUserRoleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(managedIdentityPrincipalId, keyVault.id, 'Key Vault Crypto Service Encryption User')
  scope: keyVault
  properties: {
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', 'e147488a-f6f5-4113-8e2d-b22465e65bf6') // Key Vault Crypto Service Encryption User
    principalId: managedIdentityPrincipalId
    principalType: 'ServicePrincipal'
  }
}

var keyFullRef = string(encryptionKey.properties.keyUriWithVersion)
var version = substring(keyFullRef, lastIndexOf(keyFullRef, '/') + 1, (length(keyFullRef) - 1) - lastIndexOf(keyFullRef, '/'))

output keyvaultOutput object = {
  id: keyVault.id
  name: kvName
  uri: vaultRef
  keys: [     
    {
      name: encryptionKey.name
      uri: keyFullRef
      version: version
    }
  ]
}
