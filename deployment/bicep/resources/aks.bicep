@description('Username')
param username string = 'azureuser'

@description('SSH RSA public key for all nodes.')
@secure()
param sshPublicKey string

@description('The name of the Managed Cluster resource.')
param aksClusterName string = 'aks-jmeter'

@description('The location of AKS resource.')
param location string = resourceGroup().location

@description('Disk size (in GiB) to provision for each of the agent pool nodes. This value ranges from 0 to 1023. Specifying 0 will apply the default disk size for that agentVMSize.')
@minValue(0)
@maxValue(1023)
param osDiskSizeGB int = 0

@description('The number of worker nodes for the cluster.')
@minValue(1)
@maxValue(50)
param workerNodeCount int = 3

@description('The size of the worker Virtual Machine.')
param workerNodeVMSize string = 'Standard_D2s_v3'

@description('The number of reporter nodes for the cluster.')
@minValue(1)
@maxValue(1)
param reporterNodeCount int = 1

@description('The size of the reporter Virtual Machine.')
param reporterNodeVMSize string = 'Standard_D8s_v3'

var osType = 'Linux'
var dnsPrefix = '${aksClusterName}-dns'

resource aksCluster 'Microsoft.ContainerService/managedClusters@2022-01-02-preview' = {
  location: location
  name: aksClusterName
  tags: {
    displayname: 'AKS Cluster'
  }
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    enableRBAC: false
    dnsPrefix: dnsPrefix
    agentPoolProfiles: [
      {
        name: 'workerpool'
        osDiskSizeGB: osDiskSizeGB
        count: workerNodeCount
        vmSize: workerNodeVMSize
        osType: osType
        type: 'VirtualMachineScaleSets'
        mode: 'System'
        enableAutoScaling: false
        enableNodePublicIP: false
      }
      {
        name: 'reporterpool'
        osDiskSizeGB: osDiskSizeGB
        count: reporterNodeCount
        vmSize: reporterNodeVMSize
        osType: osType
        type: 'VirtualMachineScaleSets'
        mode: 'User'
        enableAutoScaling: false
        enableNodePublicIP: false
        nodeTaints: [
          'sku=reporter:NoSchedule'
        ]
      }
    ]
    linuxProfile: {      
      adminUsername: username
      ssh: {
        publicKeys: [
          {
            keyData: sshPublicKey
          }
        ]
      }      
    }
  }
}

output aksControlPlaneFQDN string = aksCluster.properties.fqdn
output aksKubeletPrincipalID string = aksCluster.properties.identityProfile.kubeletidentity.objectId
