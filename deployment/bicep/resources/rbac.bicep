@description('The principal ID of kubelet identity.')
param kubeletIdentityPrincipalId string

@description('ACR name.')
param acrName string

var acrPullRoleId = '/subscriptions/${subscription().subscriptionId}/providers/Microsoft.Authorization/roleDefinitions/7f951dda-4ed3-4680-a7ca-43fe172d538d'
var name = guid(resourceGroup().id, acrName, kubeletIdentityPrincipalId, 'AssignAcrPullToAks')

resource acrResource 'Microsoft.ContainerRegistry/registries@2021-06-01-preview' existing = {
  name: acrName
}

resource assignAcrPullToAks 'Microsoft.Authorization/roleAssignments@2020-04-01-preview' = {
  name: name
  scope: acrResource
  properties: {
    description: 'Assign AcrPull role to AKS'
    principalId: kubeletIdentityPrincipalId
    principalType: 'ServicePrincipal'
    roleDefinitionId: acrPullRoleId
  }
}
