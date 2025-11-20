// ========== Managed Identity ========== //
targetScope = 'subscription'

@minLength(3)
@maxLength(15)
@description('Solution Name')
param solutionName string

@description('Solution Location')
param solutionLocation string

@description('Manager Resource Id. The Azure resource Id of the user or service principal who will manage this resource group.')
param managerResourceId string = ''

@description('Resource Group Name. The name of the managed resource group to be created.')
param rgName string = ''

var managedRGName = '${solutionName}_${solutionLocation}_${rgName}'

resource resourceGroup 'Microsoft.Resources/resourceGroups@2021-04-01' = {
  name: managedRGName
  location: solutionLocation
  tags: {
    app: solutionName
    location: solutionLocation
  }
  managedBy: managerResourceId
}
