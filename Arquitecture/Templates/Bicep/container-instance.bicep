// ========== Container Instance ========== //
targetScope = 'resourceGroup'

@minLength(3)
@maxLength(15)
@description('Solution Name')
param solutionName string

@description('Solution Location')
param solutionLocation string

@description('Name')
param ciName string = '${ solutionName }-ci'

@description('Managed Identity ID. The resource identifier of the UserAssigned identity to be used for the container instance deployment.')
param managedIdentityId string

@description('Container Image. The name of the image used to create the container instance..')
param containerImage string = 'mcr.microsoft.com/azuredeploymentscripts-powershell:az9.7'

@description('Volume Mounts Name. The name of the volume mount.')
param volumeMountsName string = 'filesharevolume'

@description('Mount Path. The path within the container where the volume should be mounted. Must not contain colon (:).')
param mountPath string = '/mnt/azscripts/azscriptinput'

@description('Log Analytics Log Type. The log type to be used.')
@allowed([
  'ContainerInsights'
  'ContainerInstanceLogs'
])
param logAnalyticsLogType string = 'ContainerInsights'

@description('Log Analytics Workspace Resource Id. The workspace resource id for log analytics.')
@secure()
param logAnalyticsWorkspaceResourceId string 

@description('Log Analytics Workspace Id. The workspace id for log analytics.')
@secure()
param logAnalyticsWorkspaceId string 

@description('Log Analytics Workspace Key. The workspace key for log analytics.')
@secure()
param logAnalyticsWorkspaceKey string

@description('Encryption Key Name. The encryption key name.')
param encryptionKeyName string = 'encryptionKey'

@description('Encryption Key Version. The encryption key version.')
param encryptionKeyVersion string

@description('Keyvault Base URL. The keyvault base url.')
param keyvaultBaseURL string 

@description('OS Type. The operating system type required by the containers in the container group.')
@allowed([
  'Linux'
  'Windows'
])
param osType string = 'Linux'

@description('Priority. The priority of the container group.')
@allowed([
  'Regular'
  'Spot'
])
param priority string = 'Regular'

@description('Restart Policy. Restart policy for all containers within the container group.')
@allowed([
  'OnFailure'
  'Always'
  'Never'
])
param restartPolicy string = 'OnFailure'

@description('')
@allowed([
  'Confidential'
  'Dedicated'
  'Standard'
])
param SKU string = 'Standard'

@description('Volume Name. The name of the volume.')
param volumeName string = 'filesharevolume'

@description('Storage Account Name. The name of the storage account that contains the Azure File share.')
param storageAccountName string

@description('Storage Account Key. The storage account access key used to access the Azure File share.')
@secure()
param storageAccountKey string

@description('Azure File Share Name. The name of the Azure File share to be mounted as a volume.')
param azureFileShareName string 

resource containerInstance 'Microsoft.ContainerInstance/containerGroups@2024-10-01-preview' = {
  name: ciName
  location: solutionLocation
  tags: {
    app: solutionName
    location: solutionLocation
  }
  identity: {
    type: 'UserAssigned'
    userAssignedIdentities: {
      '${managedIdentityId}' : {}
    }
  }
  properties: {    
    containers: [
      {
        name: ciName
        properties: {
          command: [
            '/bin/sh'
            '-c'
            'pwsh -c "Start-Sleep -Seconds 1800"'
          ]         
          image: containerImage          
          ports: [
            {
              port: 80
              protocol: 'TCP'
            }
          ]          
          resources: {
            limits: {
              cpu: 1             
              memoryInGB: json('2')
            }
            requests: {
              cpu: 1            
              memoryInGB: json('2')
            }
          }         
          volumeMounts: [
            {
              name: volumeMountsName
              mountPath: mountPath        
              readOnly: false
            }
          ]
        }
      }
    ]
    diagnostics: {
      logAnalytics: {
        logType: logAnalyticsLogType
        metadata: {}
        workspaceResourceId: logAnalyticsWorkspaceResourceId
        workspaceId: logAnalyticsWorkspaceId
        workspaceKey: logAnalyticsWorkspaceKey
      }
    }    
    encryptionProperties: {
      identity: managedIdentityId
      keyName: encryptionKeyName
      keyVersion: encryptionKeyVersion
      vaultBaseUrl: keyvaultBaseURL
    }     
    osType: osType
    priority: priority
    restartPolicy: restartPolicy
    sku: SKU   
    volumes: [
      {
        name: volumeName
        azureFile: {
          storageAccountName: storageAccountName
          storageAccountKey: storageAccountKey                    
          shareName: azureFileShareName                 
          readOnly: false    
        }
      }
    ]
  }
}

output containerInstanceOutput object = {
  id: containerInstance.id  
  name: containerInstance.name
}
