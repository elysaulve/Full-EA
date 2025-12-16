// ========== main.bicep ========== //
targetScope = 'subscription'

@minLength(36)
@maxLength(36)
@description('Tenant Id')
param tenantId string = subscription().tenantId

@minLength(36)
@maxLength(36)
@description('Azure Subscription Id')
param subscriptionId string = subscription().subscriptionId

@minLength(3)
@maxLength(15)
@description('Solution Name')
param solutionName string = substring(guid(subscriptionId, tenantId), 0, 15)

@description('Managed App expected managed resource group name (must match the application definition logic)')
param managedResourceGroupName string

resource managedResourceGroup 'Microsoft.Resources/resourceGroups@2025-04-01' existing = {
  name: managedResourceGroupName
}

param Location string = deployment().location

/*module resourceGroupsModule './resource-group.bicep' = {
  name: '${solutionName}-resourceGroupsDeployment'
  params: {
     solutionName: solutionName
     solutionLocation: Location
  }
  scope: subscription(subscriptionId)
}

// Resource Group Names can't be retrieved from the resourceGroupsModule output directly, since you need values calculated from the beginning of the main.bicep file deployment
var rgNetworkName = '${solutionName}_${Location}_network'
var rgServicesName = '${solutionName}_${Location}_services' 
var rgStorageName = '${solutionName}_${Location}_storage'
var rgDataName = '${solutionName}_${Location}_data'
var rgAnalyticsName = '${solutionName}_${Location}_analytics'
var rgAIName = '${solutionName}_${Location}_ai'*/

// ========== Managed Identity ========== //
module managedIdentityModule 'managed-identity.bicep' = {
  name: '${solutionName}-managedIdentityDeployment'
  params: {
    solutionName: solutionName
    solutionLocation: Location   
  }
  scope: resourceGroup(managedResourceGroup.name)
  dependsOn: [
    managedResourceGroup
  ]
}

@description('DNS Zone Name.')
param domain string

// ========== DNS Zones Module ========== //
module dnsZonesModule 'dns-zones.bicep' = {
  name: '${solutionName}-dnsZonesDeployment'
  params: {
    solutionName: solutionName
    dnsZonesName: domain
  }
  scope: resourceGroup(managedResourceGroup.name)
  dependsOn: [
    managedResourceGroup
  ]
}

// ========== Public Ip Address Module for App Gateway ========== //
module publicIpAddressAppGatewayModule 'public-ip-address.bicep' = {
  name: '${solutionName}-publicIpAddressAppGatewayDeployment'
  params: {
    solutionName: solutionName
    solutionLocation: Location
    domainNameLabel: dnsZonesModule.outputs.dnsZonesOutput.name
    pipName: '${solutionName}-pip-ag'
  }
  scope: resourceGroup(managedResourceGroup.name)
  dependsOn: [
    managedResourceGroup
  ]
}

// ========== Public Ip Address Module for Nat Gateway ========== //
module publicIpAddressNatGatewayModule 'public-ip-address.bicep' = {
  name: '${solutionName}-publicIpAddressNatGatewayDeployment'
  params: {
    solutionName: solutionName
    solutionLocation: Location
    domainNameLabel: dnsZonesModule.outputs.dnsZonesOutput.name
    pipName: '${solutionName}-pip-ng'
  }
  scope: resourceGroup(managedResourceGroup.name)
  dependsOn: [
    managedResourceGroup
  ]
}

// ========== Public Ip Address Module for Virtual Network Gateway - Default ========== //
module publicIpAddressVirtualNetworkGatewayDefaultModule 'public-ip-address.bicep' = {
  name: '${solutionName}-publicIpAddressVirtualNetworkGatewayDeployment1'
  params: {
    solutionName: solutionName
    solutionLocation: Location
    domainNameLabel: dnsZonesModule.outputs.dnsZonesOutput.name
    pipName: '${solutionName}-pip-vng-default'
  }
  scope: resourceGroup(managedResourceGroup.name)
  dependsOn: [
    managedResourceGroup
  ]
}

// ========== Public Ip Address Module for Virtual Network Gateway - Active Active ========== //
module publicIpAddressVirtualNetworkGatewayActiveActiveModule 'public-ip-address.bicep' = {
  name: '${solutionName}-publicIpAddressVirtualNetworkGatewayDeployment2'
  params: {
    solutionName: solutionName
    solutionLocation: Location
    domainNameLabel: dnsZonesModule.outputs.dnsZonesOutput.name
    pipName: '${solutionName}-pip-vng-activeactive'
  }
  scope: resourceGroup(managedResourceGroup.name)
  dependsOn: [
    managedResourceGroup
  ]
}

// ========== Public Ip Address Module ========== //
module natGatewayModule 'nat-gateway.bicep' = {
  name: '${solutionName}-natGatewayDeployment'
  params: {
    solutionName: solutionName
    solutionLocation: Location
    publicIpAddressId: publicIpAddressNatGatewayModule.outputs.publicIpAddressOutput.id
  }
  scope: resourceGroup(managedResourceGroup.name)
  dependsOn: [
    managedResourceGroup
  ]
}

// ========== Virtual Network Module ========== //
module virtualNetworkModule 'virtual-network.bicep' = {
  name: '${solutionName}-virtualNetworkDeployment'
  params: {
    solutionName: solutionName
    solutionLocation: Location
    natGatewayId: natGatewayModule.outputs.natGatewayOutput.id
  }
  scope: resourceGroup(managedResourceGroup.name)
  dependsOn: [
    managedResourceGroup
  ]
}

// ========== Public Virtual Network Module ========== //
module appGatewayModule 'application-gateway.bicep' = {
  name: '${solutionName}-appGatewayDeployment'
  params: {
    solutionName: solutionName
    solutionLocation: Location
    managedIdentityId: managedIdentityModule.outputs.managedIdentityOutput.id
    publicIpAddress: publicIpAddressAppGatewayModule.outputs.publicIpAddressOutput.id
    appGatewaySubnetId: virtualNetworkModule.outputs.virtualNetworkOutput.appGatewaySubnet.id
  }
  scope: resourceGroup(managedResourceGroup.name)
  dependsOn: [
    managedResourceGroup
  ]
}

// ========== Virtual Network Gateway Module ========== //
module virtualNetworkGatewayModule 'virtual-network-gateway.bicep' = {
  name: '${solutionName}-virtualNetworkGatewayDeployment'
  params: {
    solutionName: solutionName
    solutionLocation: Location
    managedIdentityId: managedIdentityModule.outputs.managedIdentityOutput.id
    enableBgp: true
    enableBgpRouteTranslationForNat: true
    virtualNetworkGatewayDefaultPublicIpId: publicIpAddressVirtualNetworkGatewayDefaultModule.outputs.publicIpAddressOutput.id
    virtualNetworkGatewayActiveActivePublicIpId: publicIpAddressVirtualNetworkGatewayActiveActiveModule.outputs.publicIpAddressOutput.id
    virtualNetworkGatewaySubnetId: virtualNetworkModule.outputs.virtualNetworkOutput.virtualNetworkGatewaySubnet.id
  }
  scope: resourceGroup(managedResourceGroup.name)
  dependsOn: [
    managedResourceGroup
  ]
}

// ========== Key Vault Module ========== //
module keyvaultModule 'keyvault.bicep' = {
  name: '${solutionName}-keyvaultDeployment'
  params: {
    solutionName: solutionName
    solutionLocation: Location
    tenantId: subscription().tenantId
    managedIdentityPrincipalId: managedIdentityModule.outputs.managedIdentityOutput.objectId
    enablePurgeProtection: true
    enableSoftDelete: true
  }
  scope: resourceGroup(managedResourceGroup.name)
  dependsOn: [    
    managedResourceGroup
  ]
}

@allowed([  
  'Premium_LRS'
  'Premium_ZRS'
  'Standard_GRS'
  'Standard_GZRS'
  'Standard_LRS'
  'Standard_RAGRS'
  'Standard_RAGZRS'
  'Standard_ZRS'
])
param storageSKU string = 'Standard_LRS'

// ========== Storage Account Module ========== //
module storageAccountModule 'storage-account.bicep' = {
  name: '${solutionName}-storageAccountDeployment'
  params: {
    solutionName: solutionName
    solutionLocation: Location
    saName: '${solutionName}sa'
    managedIdentityId: managedIdentityModule.outputs.managedIdentityOutput.id
    skuName: storageSKU
    keyName: keyvaultModule.outputs.keyvaultOutput.keys[0].name
    keyVersion: keyvaultModule.outputs.keyvaultOutput.keys[0].version
    keyVaultRef: keyvaultModule.outputs.keyvaultOutput.uri
  }
  scope: resourceGroup(managedResourceGroup.name)
  dependsOn: [
    managedResourceGroup    
  ]
}

// ========== Storage Account Module ========== //
module storageAccountModuleForMLWS 'storage-account.bicep' = {
  name: '${solutionName}-storageAccountDeploymentForMLWS'
  params: {
    saName: '${solutionName}samlws'
    solutionName: solutionName
    solutionLocation: Location
    managedIdentityId: managedIdentityModule.outputs.managedIdentityOutput.id
    skuName: storageSKU
    keyName: keyvaultModule.outputs.keyvaultOutput.keys[0].name
    keyVersion: keyvaultModule.outputs.keyvaultOutput.keys[0].version
    keyVaultRef: keyvaultModule.outputs.keyvaultOutput.uri
    isHnsEnabled: false
  }
  scope: resourceGroup(managedResourceGroup.name)
  dependsOn: [
    managedResourceGroup    
  ]
}

// ========== Container Registry Module ========== //
module containerRegistryModule 'container-registry.bicep' = {
  name: '${solutionName}-containerRegistryDeployment'
  params: {    
    solutionName: solutionName
    solutionLocation: Location  
    armAudienceTokenPolicyStatus: 'Enabled'
    sku: 'Premium'
    managedIdentityId: managedIdentityModule.outputs.managedIdentityOutput.id    
    managedIdentityPrincipalId: managedIdentityModule.outputs.managedIdentityOutput.objectId    
    keyVaultIdentity: managedIdentityModule.outputs.managedIdentityOutput.clientId
    keyVaultKeyIdentifier: keyvaultModule.outputs.keyvaultOutput.keys[0].uri
    keyVaultStatus: 'Enabled'    
  }
  scope: resourceGroup(managedResourceGroup.name)
  dependsOn: [
    managedResourceGroup    
  ]
}

// ========== Log Analytics Workspace Module ========== //
module logsAnalyticsWorkspaceModule 'log-analytics-workspace.bicep' = {
  name: '${solutionName}-logAnalyticsWorkspaceDeployment'
  params: {
    solutionName: solutionName
    solutionLocation: Location
    managedIdentityId: managedIdentityModule.outputs.managedIdentityOutput.id
  }
  scope: resourceGroup(managedResourceGroup.name)
  dependsOn: [
    managedResourceGroup    
  ]
} 

// ========== Container Instance Module ========== //
/*module containerInstanceWorkspaceModule 'container-instance.bicep' = {
  name: '${solutionName}-containerInstanceDeployment'
  params: {
    solutionName: solutionName
    solutionLocation: Location    
    managedIdentityId: managedIdentityModule.outputs.managedIdentityOutput.id
    logAnalyticsWorkspaceResourceId: logsAnalyticsWorkspaceModule.outputs.logAnalyticsWorkspaceOutput.id  
    logAnalyticsWorkspaceId: logsAnalyticsWorkspaceModule.outputs.logAnalyticsWorkspaceOutput.workspaceId
    logAnalyticsWorkspaceKey: logsAnalyticsWorkspaceModule.outputs.logAnalyticsWorkspaceOutput.workspaceKey
    encryptionKeyName: keyvaultModule.outputs.keyvaultOutput.keys[0].name
    encryptionKeyVersion: keyvaultModule.outputs.keyvaultOutput.keys[0].version   
    keyvaultBaseURL: keyvaultModule.outputs.keyvaultOutput.uri  
    storageAccountName: storageAccountModule.outputs.storageAccountOutput.name
    storageAccountKey: storageAccountModule.outputs.storageAccountOutput.key
    azureFileShareName: storageAccountModule.outputs.storageAccountOutput.shares[0].name    
  }
  scope: resourceGroup(rgServicesName)
  dependsOn:[
    containerRegistryModule
    resourceGroupsModule
  ]
}*/

//========== Application Insights Module ========== //
module applicationInsightsModule 'application-insights.bicep' = {
  name: '${solutionName}-applicationInsightsDeployment'
  params: {
    solutionName: solutionName
    solutionLocation: Location
    workspaceResourceId: logsAnalyticsWorkspaceModule.outputs.logAnalyticsWorkspaceOutput.Id
  }
  scope: resourceGroup(managedResourceGroup.name) 
  dependsOn: [
    managedResourceGroup    
  ]
}

@minLength(5)
@maxLength(30)
@description('Linux Admin Username')
param linuxAdminUserName string

@description('SSH RSA Publick Key')
param sshRSAPublicKey string

@description('AKS VM Size. Size of the Virtual Machines to be used as nodes in the Kubernetes cluster.')
param aksVMSize string = 'Standard_B2S'

@description('AKS VM Count. Count of the Virtual Machines to be used as nodes in the Kubernetes cluster.')
param aksVMCount int = 3

// ========== Kubernetes Services Module ========== //
module kubernetesServicesModule 'kubernetes-services.bicep' = {
  name: '${solutionName}-kubernetesServicesDeployment'
  params: {
    solutionName: solutionName
    solutionLocation: Location
    dnsPrefix: solutionName    
    tenantId: tenantId        
    linuxAdminUsername: linuxAdminUserName
    sshRSAPublicKey: sshRSAPublicKey
    managedIdentityId: managedIdentityModule.outputs.managedIdentityOutput.id
    managedIdentityPrincipalId: managedIdentityModule.outputs.managedIdentityOutput.objectId
    enableAzureRBAC: true
    servicesSubnetId: virtualNetworkModule.outputs.virtualNetworkOutput.servicesSubnet.id
    agentVMSize: aksVMSize
    agentCount: aksVMCount
    orchestratorVersion: '1.32.7'
    keyId: keyvaultModule.outputs.keyvaultOutput.keys[0].uri 
    keyVaultKmsEnabled: true
    defenderEnabled: true
    logAnalyticsWorkspaceResourceId: logsAnalyticsWorkspaceModule.outputs.logAnalyticsWorkspaceOutput.id
    webAppRoutingEnabled: true
    dnsZoneResourceId: dnsZonesModule.outputs.dnsZonesOutput.id    
    appGatewayId: appGatewayModule.outputs.appGatewayOutput.id
  }
  scope: resourceGroup(managedResourceGroup.name)
  dependsOn: [
    managedResourceGroup
    containerRegistryModule            
  ]
}

// ========== AGIC Role Assigment ========== //
module agicReaderRoleAssignmentToNetworkRG 'agic-reader-role-assignment.bicep' = {
  name: '${solutionName}-agicReaderRoleAssignment'
  params: {
    kubeletIdentityClientId: kubernetesServicesModule.outputs.kubernetesServicesOutput.kubeletIdentityClientId
    kubeletIdentityObjectId: kubernetesServicesModule.outputs.kubernetesServicesOutput.kubeletIdentityObjectId
  }
  scope: resourceGroup(managedResourceGroup.name)
  dependsOn: [
    managedResourceGroup    
  ]
}

// ========== AGIC Role Assigment ========== //
module agicContributorRoleAssignment 'agic-contributor-role-assignment.bicep' = {
  name: '${solutionName}-agicContributorRoleAssignment'
  params: {
    appGatewayName: appGatewayModule.outputs.appGatewayOutput.name
    kubeletIdentityClientId: kubernetesServicesModule.outputs.kubernetesServicesOutput.kubeletIdentityClientId
    kubeletIdentityObjectId: kubernetesServicesModule.outputs.kubernetesServicesOutput.kubeletIdentityObjectId
    appGatewaySubnetName: '${virtualNetworkModule.outputs.virtualNetworkOutput.name}/${virtualNetworkModule.outputs.virtualNetworkOutput.appGatewaySubnet.name}'
    servicesSubnetName: '${virtualNetworkModule.outputs.virtualNetworkOutput.name}/${virtualNetworkModule.outputs.virtualNetworkOutput.servicesSubnet.name}'
  }
  scope: resourceGroup(managedResourceGroup.name)
  dependsOn: [
    managedResourceGroup    
  ]
}

// ========== AGIC Role Assigment ========== //
module agicManagedIdentityOperatorRoleAssignment 'agic-managed-identity-operator-role-assignment.bicep' = {
  name: '${solutionName}-agicManagedIdentityOperatorRoleAssignment'
  params: {
    managedIdentityClientId: managedIdentityModule.outputs.managedIdentityOutput.id
    managedIdentityName: managedIdentityModule.outputs.managedIdentityOutput.name
    kubeletIdentityClientId: kubernetesServicesModule.outputs.kubernetesServicesOutput.kubeletIdentityClientId
    kubeletIdentityObjectId: kubernetesServicesModule.outputs.kubernetesServicesOutput.kubeletIdentityObjectId
  }
  scope: resourceGroup(managedResourceGroup.name)
  dependsOn: [
    managedResourceGroup    
  ]
}

@description('SQL Administrator Login.')
param sqlAdminUsername string 

@description('SQL Administrator Password.')
@secure()
param sqlAdminPassword string 

// ========== SQL Server ========== //
module sqlServerModule 'sql-server.bicep' = {
  name: '${solutionName}-sqlServerDeployment'
  params: {
    solutionName: solutionName
    solutionLocation: Location
    managedIdentityId: managedIdentityModule.outputs.managedIdentityOutput.id
    sqlAdminUsername: sqlAdminUsername
    sqlAdminPassword: sqlAdminPassword
    dataEncryptionKeyRef: keyvaultModule.outputs.keyvaultOutput.keys[0].uri    
  }
  scope: resourceGroup(managedResourceGroup.name)
  dependsOn: [
    managedResourceGroup    
  ]
}

// ========== Cosmos DB ========== //
module cosmosDbModule 'cosmos-db-sql.bicep' = {
  name: '${solutionName}-cosmosDbDeployment'
  params: {
    solutionName: solutionName
    solutionLocation: Location
    managedIdentityId: managedIdentityModule.outputs.managedIdentityOutput.id
  }
  scope: resourceGroup(managedResourceGroup.name)
  dependsOn: [
    managedResourceGroup    
  ]
}

// ========== Data Factory ========== //
module dataFactoryModule 'data-factory.bicep' = {
  name: '${solutionName}-dataFactoryDeployment'
  params: {
    solutionName: solutionName
    solutionLocation: Location
    managedIdentityId: managedIdentityModule.outputs.managedIdentityOutput.id
    encryptionKeyName: keyvaultModule.outputs.keyvaultOutput.keys[0].name
    encryptionKeyVersion: keyvaultModule.outputs.keyvaultOutput.keys[0].version   
    encryptionKeyVaultRef: keyvaultModule.outputs.keyvaultOutput.uri  
  }
  scope: resourceGroup(managedResourceGroup.name)
  dependsOn: [
    managedResourceGroup    
  ]
}

// ========== Machine Learning Workspace ========== //
module machineLearningWorkspaceModule 'machine-learning-workspace.bicep' = {
  name: '${solutionName}-machineLearningWorkspaceDeployment'
  params: {
    solutionName: solutionName
    solutionLocation: Location   
    managedIdentityId: managedIdentityModule.outputs.managedIdentityOutput.id
    keyVault: keyvaultModule.outputs.keyvaultOutput.id
    storageAccount: storageAccountModuleForMLWS.outputs.storageAccountOutput.id
    containerRegistry: containerRegistryModule.outputs.containerRegistryOutput.id
    applicationInsights: applicationInsightsModule.outputs.applicationInsightsOutput.id
  }
  scope: resourceGroup(managedResourceGroup.name)
  dependsOn: [
    managedResourceGroup    
  ]
}

var azureDatabricksEnterpriseApplicationObjectId = '4e0ed970-b4e4-4fac-be7b-c73ff733bf7c'

// ========== Key Vault Role Assignment for Managed Identity ========== //
module dbwsKeyVaultCryptoServiceEncryptionUserRoleAssignment 'keyvault-crypto-service-encryption-user-role-assignment.bicep' = {
  name: '${solutionName}-dbwskvCryptoServiceEncryptionUserRoleAssignment'
  params: {
    managedIdentityId: 'databricksWorkspaceManagedIdentityClientId'
    managedIdentityPrincipalId: azureDatabricksEnterpriseApplicationObjectId
    keyvaultName: keyvaultModule.outputs.keyvaultOutput.name
  }
  scope: resourceGroup(managedResourceGroup.name)
  dependsOn: [
    managedResourceGroup    
  ]
}

// ========== Databricks Workspace ========== //
module databricksWorkspaceModule 'databricks-workspace.bicep' = {
  name: '${solutionName}-databricksWorkspaceDeployment'
  params: {
    solutionName: solutionName
    solutionLocation: Location  
    dbwsName: '${solutionName}-dbws' 
    managedIdentityId: managedIdentityModule.outputs.managedIdentityOutput.id
    managedIdentityPrincipalId: managedIdentityModule.outputs.managedIdentityOutput.objectId
    amlWorkspaceId: machineLearningWorkspaceModule.outputs.machineLearningWorkspaceOutput.id
    customVirtualNetworkId: virtualNetworkModule.outputs.virtualNetworkOutput.id
    customPrivateSubnetName: virtualNetworkModule.outputs.virtualNetworkOutput.databricksSubnetPrivate.name
    customPublicSubnetName: virtualNetworkModule.outputs.virtualNetworkOutput.databricksSubnetPublic.name
    storageAccountName: '${solutionName}dbwssa'
    storageAccountSKU: storageAccountModule.outputs.storageAccountOutput.sku
    keyVaultRef: keyvaultModule.outputs.keyvaultOutput.uri
    encryptionKeyName: keyvaultModule.outputs.keyvaultOutput.keys[0].name
    encryptionKeyVersion: keyvaultModule.outputs.keyvaultOutput.keys[0].version
  }
  scope: resourceGroup(managedResourceGroup.name)
  dependsOn: [
    managedResourceGroup  
    virtualNetworkGatewayModule 
  ]
}

// ========== Synapse Analytics Workspace ========== //
module synapseAnalyticsWorkspaceModule 'synapse-analytics-workspace.bicep' = {
  name: '${solutionName}-synapseAnalyticsWorkspaceDeployment'
  params: {
    solutionName: solutionName
    solutionLocation: Location
    dlsResourceId: storageAccountModuleForMLWS.outputs.storageAccountOutput.id
    dlsAccountRef: storageAccountModuleForMLWS.outputs.storageAccountOutput.dfs
    dlsFileSystem: storageAccountModuleForMLWS.outputs.storageAccountOutput.dataContainer
    managedIdentityId: managedIdentityModule.outputs.managedIdentityOutput.id
  }
  scope: resourceGroup(managedResourceGroup.name)
}

// ========== Private End-Points ========== //
// ========== Private End-Point AKS-ASA ========== //
module privateEndpointAKStoASAModule 'private-endpoint.bicep' = {
  name: '${solutionName}-privateEndpointFromAKSToASADeployment'
  params: {
    solutionLocation: Location
    serviceName: kubernetesServicesModule.outputs.kubernetesServicesOutput.name
    subnetId: virtualNetworkModule.outputs.virtualNetworkOutput.servicesSubnet.id
    resourceNameForPE: storageAccountModule.outputs.storageAccountOutput.name
    resourceIdForPE: storageAccountModule.outputs.storageAccountOutput.id
    resourceGroupIdsForPE: [
      'blob'
    ]
  }
  scope: resourceGroup(managedResourceGroup.name)
  dependsOn:[
    managedResourceGroup
  ]
}

// ========== Private DNS Zone AKA-ASA ========== //
module privateDnsZoneAKStoASAModule 'private-dns-zone.bicep' = {
  name: '${solutionName}-privateDnsZoneFromAKSToASADeployment'
  params: {
    solutionName: solutionName
    privateEndPointName: privateEndpointAKStoASAModule.outputs.resourcePrivateEndPointOutput.name
    privateDNSZoneName: '${solutionName}.privatelink.blob.${environment().suffixes.storage}'
  }
  scope: resourceGroup(managedResourceGroup.name)
  dependsOn:[
    managedResourceGroup
  ]
}

// ========== Private End-Point AKS-ACR ========== //
module privateEndpointAKStoACRModule 'private-endpoint.bicep' = {
  name: '${solutionName}-privateEndpointFromAKSToACRDeployment'
  params: {
    solutionLocation: Location
    serviceName: kubernetesServicesModule.outputs.kubernetesServicesOutput.name
    subnetId: virtualNetworkModule.outputs.virtualNetworkOutput.servicesSubnet.id
    resourceNameForPE: containerRegistryModule.outputs.containerRegistryOutput.name
    resourceIdForPE: containerRegistryModule.outputs.containerRegistryOutput.id
    resourceGroupIdsForPE: [
      'registry'
    ]
  }
  scope: resourceGroup(managedResourceGroup.name)
  dependsOn:[
    managedResourceGroup
  ]
}

// ========== Private DNS Zone AKS-ACR ========== //
module privateDnsZoneAKStoACRModule 'private-dns-zone.bicep' = {
  name: '${solutionName}-privateDnsZoneFromAKSToACRDeployment'
  params: {
    solutionName: solutionName
    privateEndPointName: privateEndpointAKStoACRModule.outputs.resourcePrivateEndPointOutput.name
    privateDNSZoneName: '${solutionName}.privatelink${environment().suffixes.acrLoginServer}'
  }
  scope: resourceGroup(managedResourceGroup.name)
  dependsOn:[
    managedResourceGroup
  ]
}

// ========== Private End-Point AKS-SQL ========== //
module privateEndpointAKStoSQLModule 'private-endpoint.bicep' = {
  name: '${solutionName}-privateEndpointFromAKSToSQLDeployment'
  params: {
    solutionLocation: Location
    serviceName: kubernetesServicesModule.outputs.kubernetesServicesOutput.name
    subnetId: virtualNetworkModule.outputs.virtualNetworkOutput.servicesSubnet.id
    resourceNameForPE: sqlServerModule.outputs.sqlServerOutput.name
    resourceIdForPE: sqlServerModule.outputs.sqlServerOutput.id
    resourceGroupIdsForPE: [
      'sqlServer'
    ]
  }
  scope: resourceGroup(managedResourceGroup.name)
  dependsOn:[
    managedResourceGroup
  ]
}

// ========== Private DNS Zone AKS-SQL ========== //
module privateDnsZoneAKStoSQLModule 'private-dns-zone.bicep' = {
  name: '${solutionName}-privateDnsZoneFromAKSToSQLDeployment'
  params: {
    solutionName: solutionName
    privateEndPointName: privateEndpointAKStoSQLModule.outputs.resourcePrivateEndPointOutput.name
    privateDNSZoneName: '${solutionName}.privatelink${environment().suffixes.sqlServerHostname}'
  }
  scope: resourceGroup(managedResourceGroup.name)
  dependsOn:[
    managedResourceGroup
  ]
}

/*
// ========== Scripts Deployment ========== //
module scriptsDeploymentModule 'scripts-deployment.bicep' = {
  name: 'scriptsDeployment'
  params: {
    solutionName: solutionName
    solutionLocation: solutionLocation    
    //AKS Properties
    aksName: kubernetesServicesModule.outputs.kubernetesServicesOutput.name
    //Identity Properties
    userAssignedIdentity: managedIdentityModule.outputs.managedIdentityOutput.id
  }
  scope: resourceGroup(rgServicesName)
}*/
