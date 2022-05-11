@description('SSH RSA public key for all AKS nodes.')
@secure()
param sshPublicKey string

@description('Provide a location for the deployment.')
param location string = resourceGroup().location

module acr 'resources/acr.bicep' = {
  name: 'acrDeploy'
  params: {
    location: location
  }
}

module aks 'resources/aks.bicep' = {
  name: 'aksDeploy'
  params: {
    location: location
    sshPublicKey: sshPublicKey
  }
}

module rbac 'resources/rbac.bicep' = {
  name: 'acrPullToAksRbacDeploy'
  params: {
    acrName: acr.outputs.acrName
    kubeletIdentityPrincipalId: aks.outputs.aksKubeletPrincipalID
  }
}
