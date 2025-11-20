// =========== resource groups ===========

// Setting target scope
targetScope = 'subscription'

@minLength(3)
@maxLength(15)
@description('Project Name:')
param solutionName string

@description('Project Location:')
param solutionLocation string

var rgNames = [
  '${solutionName}_${solutionLocation}_network'
  '${solutionName}_${solutionLocation}_services'
  '${solutionName}_${solutionLocation}_data'
  '${solutionName}_${solutionLocation}_storage' 
  '${solutionName}_${solutionLocation}_ai' 
  '${solutionName}_${solutionLocation}_analytics' 
]

resource resourceGroupNetwork 'Microsoft.Resources/resourceGroups@2021-04-01' = {
  name: rgNames[0]
  location: solutionLocation
  tags: {
    app: solutionName
    location: solutionLocation
  }
}

resource resourceGroupServices 'Microsoft.Resources/resourceGroups@2021-04-01' = {
  name: rgNames[1]
  location: solutionLocation
  tags: {
    app: solutionName
    location: solutionLocation
  }
}

resource resourceGroupData 'Microsoft.Resources/resourceGroups@2021-04-01' = {
  name: rgNames[2]
  location: solutionLocation
  tags: {
    app: solutionName
    location: solutionLocation
  }
}

resource resourceGroupStorage 'Microsoft.Resources/resourceGroups@2021-04-01' = {
  name: rgNames[3]
  location: solutionLocation
  tags: {
    app: solutionName
    location: solutionLocation
  }
}

resource resourceGroupAI 'Microsoft.Resources/resourceGroups@2021-04-01' = {
  name: rgNames[4]
  location: solutionLocation
  tags: {
    app: solutionName
    location: solutionLocation
  }
}

resource resourceGroupAnalytics 'Microsoft.Resources/resourceGroups@2021-04-01' = {
  name: rgNames[5]
  location: solutionLocation
  tags: {
    app: solutionName
    location: solutionLocation
  }
}

output resourceGroupsOutput object = {
  network: {
    id: resourceGroupNetwork.id
    name: resourceGroupNetwork.name
    location: resourceGroupNetwork.location
    properties: resourceGroupNetwork.properties
  }
  services: {
    id: resourceGroupServices.id
    name: resourceGroupServices.name
    location: resourceGroupServices.location
    properties: resourceGroupServices.properties
  }
  data: {
    id: resourceGroupData.id
    name: resourceGroupData.name
    location: resourceGroupData.location
    properties: resourceGroupData.properties
  }
  storage: {
    id: resourceGroupStorage.id
    name: resourceGroupStorage.name
    location: resourceGroupStorage.location
    properties: resourceGroupStorage.properties
  }
  ai: {
    id: resourceGroupAI.id
    name: resourceGroupAI.name
    location: resourceGroupAI.location
    properties: resourceGroupAI.properties
  }
  analytics: {
    id: resourceGroupAnalytics.id
    name: resourceGroupAnalytics.name
    location: resourceGroupAnalytics.location
    properties: resourceGroupAnalytics.properties
  }
}
