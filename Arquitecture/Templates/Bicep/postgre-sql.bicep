//---------- Postgre SQL Server ----------//
@minLength(3)
@maxLength(15)
@description('Solution Name')
param solutionName string

@description('Solution Location')
param solutionLocation string = resourceGroup().location

@description('Postgre SQL Name')
param postgreSqlName string = '${ solutionName }psql'

@description('Managed Identity Type. ')
@allowed([
  'None'
  'SystemAssigned'
  'UserAssigned'
])
param identityType string = 'UserAssigned'

@description('User Assigned Identities. Gets or sets a list of key value pairs that describe the set of User Assigned identities that will be used with this storage account.')
param userAssignedIdentity string

@description('SKU Name. The name of the sku, typically, tier + family + cores, e.g. Standard_D4s_v3.')
param skuName string = 'Standard_B1ms'

@description('SKU Tier. The tier of the particular SKU, e.g. Burstable.')
@allowed([
  'Burstable'
  'GeneralPurpose'
  'MemoryOptimized'
])
param skuTier string = 'Burstable'

@description('Administrator Login. The administrator\'s login name of a server. Can only be specified when the server is being created (and is required for creation).')
param administratorLogin string 

@description('Administrator Login Password. The administrator login password (required for server creation).')
@secure()
param administratorLoginPassword string

@description('Active Directory Auth. If Enabled, Azure Active Directory authentication is enabled.')
@allowed([
  'Enabled'
  'Disabled'
])
param activeDirectoryAuth string = 'Enabled'

@description('Password Auth. If Enabled, Password authentication is enabled.')
@allowed([
  'Enabled'
  'Disabled'
])
param passwordAuth string = 'Enabled'

@description('Tenant Id')
param tenantId string = ''

@description('Backup Retention Days. Backup retention days for the server.')
param backupRetentionDays int = 10

@description('Geo-Redundant Backup. A value indicating whether Geo-Redundant backup is enabled on the server.')
@allowed([
  'Enabled'
  'Disabled'
])
param geoRedundantBackup string = 'Disabled'

@description('Create Mode. The mode to create a new PostgreSQL server.')
@allowed([
  'Create' 
  'Default' 
  'GeoRestore' 
  'PointInTimeRestore' 
  'Replica' 
  'ReviveDropped' 
  'Update'
])
param createMode string = 'Default'

@description('Storage Auto-Grow. Flag to enable / disable Storage Auto grow for flexible server.')
@allowed([
  'Enabled'
  'Disabled'
])
param storageAutoGrow string = 'Enabled'

@description('Storage Size GB. Max storage allowed for a server.')
param storageSizeGB int = 32

@description('')
param storageTier string = 'P4'

@description('Version. PostgreSQL Server version.')
param version string = '15'

@description('Data Encryption Primary Key URI. URI for the key in keyvault for data encryption of the primary server.')
param dataEncryptionPrimaryKeyURI string

@description('Data Encryption Geo-Backup Key URI. URI for the key in keyvault for data encryption for geo-backup of server.')
param dataEncryptionGeoBackupKeyURI string 

@description('Data Encryption Type. Data encryption type to depict if it is System Managed vs Azure Key vault.')
@allowed([
  'AzureKeyVault'
  'SystemManaged'
])
param dataEncryptionType string = 'AzureKeyVault'

resource postgreSql 'Microsoft.DBforPostgreSQL/flexibleServers@2023-03-01-preview' = {
  name: postgreSqlName
  location: solutionLocation
  tags: {
    app: solutionName
    location: solutionLocation
  }
  identity: {
    type: identityType
    userAssignedIdentities: {
      '${ userAssignedIdentity }' : {}
    }
  }
  sku: {
    name: skuName
    tier: skuTier
  }
  properties: {
    administratorLogin: administratorLogin
    administratorLoginPassword: administratorLoginPassword
    authConfig: {
      activeDirectoryAuth: activeDirectoryAuth
      passwordAuth: passwordAuth
      tenantId: tenantId
    }    
    backup: {
      backupRetentionDays: backupRetentionDays
      geoRedundantBackup: geoRedundantBackup
    }
    createMode: createMode
    dataEncryption: {
      //geoBackupKeyURI: dataEncryptionGeoBackupKeyURI
      //geoBackupUserAssignedIdentityId: userAssignedIdentity
      primaryKeyURI: dataEncryptionPrimaryKeyURI
      primaryUserAssignedIdentityId: userAssignedIdentity
      type: dataEncryptionType 
    }
    /*availabilityZone: ''
    highAvailability: {
      mode: 'string'
      standbyAvailabilityZone: 'string'
    }
    maintenanceWindow: {
      customWindow: 'string'
      dayOfWeek: int
      startHour: int
      startMinute: int
    }
    network: {
      delegatedSubnetResourceId: 'string'
      privateDnsZoneArmResourceId: 'string'
    }
    pointInTimeUTC: 'string'
    replicationRole: 'string'
    sourceServerResourceId: 'string'*/
    storage: {
      autoGrow: storageAutoGrow
      storageSizeGB: storageSizeGB
      tier: storageTier
    }
    version: version
  }
}
