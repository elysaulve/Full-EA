// ========== Kubernetes Services ========== //
targetScope = 'resourceGroup'

@description('Solution Name.')
param solutionName string = ''

@description('Solution Location.')
param solutionLocation string = resourceGroup().location

var ksName = '${ solutionName }-ks'

@description('SKU Tier. If not specified, the default is \'Free\'.')
@allowed([
  'Free'
  'Standard'
  'Premium'
])
param skuTier string = 'Free'

@description('Managed Identity Id. The resource ID of the user assigned managed identity to be used by the AKS cluster.')
param managedIdentityId string

@description('Managed Identity Principal Id. The principal ID of the user assigned managed identity to be used by the AKS cluster.')
param managedIdentityPrincipalId string 

@description('DNS Prefix. Optional DNS prefix to use with hosted Kubernetes API server FQDN.')
param dnsPrefix string = ''

@description('FQDN SubDomain. This cannot be updated once the Managed Cluster has been created.')
param fqdnSubdomain string = ''

@description('Enable Azure RBAC. Whether to enable Azure RBAC for Kubernetes authorization.')
param enableAzureRBAC bool = true

@description('Tenant Id. The AAD tenant ID to use for authentication. If not specified, will use the tenant of the deployment subscription.')
param tenantId string = subscription().tenantId

@description('Service Subnet Id. If this is not specified, a vnet and subnet will be generated and used. If no podSubnetID is specified, this applies to nodes and pods, otherwise it applies to just nodes. This is of the form: /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Network/virtualNetworks/{virtualNetworkName}/subnets/{subnetName}')
param servicesSubnetId string = ''

@description('OS Disk Size Gb. Disk size (in GB) to provision for each of the agent pool nodes. This value ranges from 0 to 1023. Specifying 0 will apply the default disk size for that agentVMSize.')
@minValue(0)
@maxValue(1023)
param osDiskSizeGB int = 128

@description('Agent Count. The number of nodes for the cluster.')
@minValue(1)
@maxValue(50)
param agentCount int = 1

@description('The size of the Virtual Machine.')
param agentVMSize string = 'standard_b2ms'

@description('Orchestrator Version.')
param orchestratorVersion string = '1.32.6'

@description('Linux Admin Username. User name for the Linux Virtual Machines.')
param linuxAdminUsername string

@description('SSH-RSA Public Key. Configure all linux machines with the SSH RSA public key string. Your key should include three parts, for example \'ssh-rsa AAAAB...snip...UcyupgH azureuser@linuxvm\'')
param sshRSAPublicKey string

@description('Public Network Access. Allow or deny public network access for AKS')  
@allowed([
  'Enabled'
  'Disabled'
])
param publicNetworkAccess string = 'Enabled'

@description('Azure KeyVault KMS Enabled. Whether to enable Azure Key Vault key management service. The default is false.')
param keyVaultKmsEnabled bool = false

@description('Key Id. Identifier of Azure Key Vault key.')
param keyId string = ''

@description('KeyVault Network Access. Network access of key vault. The possible values are Public and Private. Public means the key vault allows public access from all networks. Private means the key vault disables public access and enables private link. The default value is Public.')
@allowed([
  'Public'
  'Private'
])
param keyVaultNetworkAccess string = 'Public'

@description('KeyVault Resource Id. Resource ID of key vault. When keyVaultNetworkAccess is Private, this field is required and must be a valid resource ID. When keyVaultNetworkAccess is Public, leave the field empty.')
param keyVaultResourceId string = ''

@description('Defender Enabled. Microsoft Defender settings for the security profile.')
param defenderEnabled bool = true

@description('Log Analytics Workspace Resource Id. Resource ID of the Log Analytics workspace to be associated with Microsoft Defender. When Microsoft Defender is enabled, this field is required and must be a valid workspace resource ID. When Microsoft Defender is disabled, leave the field empty.')
param logAnalyticsWorkspaceResourceId string = ''

@description('Web App Routing Enabled. Whether to enable Web App Routing.')
param webAppRoutingEnabled bool = true

@description('DNS Zone Resource Id. Resource ID of the DNS Zone to be associated with the web app. Used only when Web App Routing is enabled.')
param dnsZoneResourceId string 

@description('Application Gateway Id. The resource ID of the Application Gateway to be used for ingress. This is required when using the Application Gateway Ingress Controller addon.')
param appGatewayId string 

resource kubernetesServices 'Microsoft.ContainerService/managedClusters@2025-03-02-preview' = {
  name: ksName
  location: solutionLocation
  tags: {
    app: solutionName
    location: solutionLocation
  }  
  sku: {
    name: 'Base'
    tier: skuTier
  }  
  identity: {
    type: 'UserAssigned'
    userAssignedIdentities: {
      '${managedIdentityId}' : {}
    }
  }
  properties: {
    dnsPrefix: dnsPrefix
    fqdnSubdomain: fqdnSubdomain
    aadProfile: {           
      enableAzureRBAC: enableAzureRBAC
      managed: true   
      tenantID: tenantId
    }
    agentPoolProfiles: [
      {
        vnetSubnetID: servicesSubnetId
        name: 'agentpool'
        osDiskType: 'Managed'        
        osDiskSizeGB: osDiskSizeGB              
        count: agentCount
        vmSize: agentVMSize
        osType: 'Linux'
        mode: 'System'
        kubeletDiskType: 'OS'
        maxPods: 110
        type: 'VirtualMachineScaleSets'
        maxCount: 3
        minCount: 1
        enableAutoScaling: true
        powerState: {
          code: 'Running'
        }
        orchestratorVersion: orchestratorVersion   
        upgradeSettings: {}
        enableFIPS: false          
      }
    ]
    linuxProfile: {
      adminUsername: linuxAdminUsername
      ssh: {
        publicKeys: [
          {
            keyData: sshRSAPublicKey
          }
        ]
      }
    }
    servicePrincipalProfile: {
      clientId: managedIdentityPrincipalId
    }
    publicNetworkAccess: publicNetworkAccess
    securityProfile: {
      azureKeyVaultKms: {
        enabled: keyVaultKmsEnabled
        keyId: keyId
        keyVaultNetworkAccess: keyVaultNetworkAccess
        keyVaultResourceId: keyVaultResourceId        
      }
      defender: {        
        securityMonitoring: {
          enabled: defenderEnabled
        }
        logAnalyticsWorkspaceResourceId: logAnalyticsWorkspaceResourceId
      }        
    }
    networkProfile: {
      networkPlugin: 'azure'
      networkPluginMode: 'overlay'
      loadBalancerSku: 'standard'
      outboundType: 'userassignedNATGateway'
      serviceCidr: '10.0.0.0/16'
      dnsServiceIP: '10.0.0.10'
      podCidr: '10.10.0.0/16'
      natGatewayProfile: {
        idleTimeoutInMinutes: 5
        managedOutboundIPProfile: {
          count: 1
        } 
      }
      staticEgressGatewayProfile: {
        enabled: true
      }
    }
    addonProfiles: {      
      ingressApplicationGateway: {  
        enabled: true
        config: {
          applicationGatewayId: appGatewayId     
        }        
      }
    } 
    ingressProfile: {
      webAppRouting: {
        enabled: webAppRoutingEnabled
        dnsZoneResourceIds: [
          dnsZoneResourceId
        ]       
      }
    }     
    storageProfile: {
      diskCSIDriver: {
        enabled: true
      }
      fileCSIDriver: {
        enabled: true
      }
      snapshotController: {
        enabled: true
      }
    }
    oidcIssuerProfile: {
      enabled: false
    }
    workloadAutoScalerProfile: {}
    metricsProfile: {
      costAnalysis: {
        enabled: false
      }
    }      
  }
}

resource managedIdentityAKSRBAClusterAdminRoleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(managedIdentityId, kubernetesServices.name, 'Azure Kubernetes Service RBAC Cluster Admin')
  scope: kubernetesServices
  properties: {
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', 'b1ff04bb-8a4e-4dc4-8eb5-8693973ce19b') // Azure Kubernetes Service RBAC Cluster Admin
    principalId: managedIdentityPrincipalId
    principalType: 'ServicePrincipal'
  }
}

output kubernetesServicesOutput object = {
  id: kubernetesServices.id
  name: kubernetesServices.name
  kubeletIdentityClientId: kubernetesServices.properties.addonProfiles.ingressApplicationGateway.identity.clientId
  kubeletIdentityObjectId: kubernetesServices.properties.addonProfiles.ingressApplicationGateway.identity.objectId
}
