// ========== Managed Identity ========== //
@minLength(3)
@maxLength(15)
@description('Solution Name')
param solutionName string

@description('Solution Location')
param solutionLocation string

@description('Name')
param maName string = '${ solutionName }-ma'

@description('SKU. The name of the SKU, in standard format (such as S0).')
@allowed([
  'S0'
  'S1'
  'G2'
])
param SKU string = 'G2'

@description('Kind. Get or Set Kind property.')
@allowed([
  'Gen1'
  'Gen2'
])
param Kind string = 'Gen2'

@description('Linked Resources Id. ARM resource id in the form: "/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Storage/accounts/{storageName}."')
param linkedResourcesId string 

@description('Linked Resources Unique Name. A provided name which uniquely identifies the linked resource.')
param linkedResourcesUniqueName string

resource mapsAccount 'Microsoft.Maps/accounts@2021-12-01-preview' = {
  name: maName
  location: 'Global'
  tags: {
    app: solutionName
    location: 'Global'
  }
  sku: {
    name: SKU
  }
  kind: Kind  
  properties: {
    cors: {
      corsRules: [
        {
          allowedOrigins: [
            
          ]
        }
      ]
    }
    disableLocalAuth: false
    linkedResources: [
      {
        id: linkedResourcesId
        uniqueName: linkedResourcesUniqueName
      }
    ]
  }
}
