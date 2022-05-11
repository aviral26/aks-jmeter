# AKS based scalable Jmeter Test Framework with Grafana

# ACR Load Testing

- [AKS based scalable Jmeter Test Framework with Grafana](#aks-based-scalable-jmeter-test-framework-with-grafana)
- [ACR Load Testing](#acr-load-testing)
  - [Quickstart: Using JMeter on AKS for distributed testing](#quickstart-using-jmeter-on-aks-for-distributed-testing)
    - [Prerequisites](#prerequisites)
    - [Prepare JMeter test plan](#prepare-jmeter-test-plan)
    - [Setup Azure Environment](#setup-azure-environment)
    - [Run Jmeter test](#run-jmeter-test)

## Quickstart: Using JMeter on AKS for distributed testing

TODO - add description

### Prerequisites
TODO - add links
1. JMeter
2. Kubectl
3. helm
4. az cli
5. jq

### Prepare JMeter test plan

TODO

### Setup Azure Environment 

TODO - summarize

1. Initialize variables.

```bash
# 1. The subscription where the test resources will be deployed.
# 2. Deployment location. Validate that the location supports the VM sizes referenced in the bicep files.
# 3. Name of the resource group.
# 4. String constant used to identify reporter nodes and pods.
# 5. Jmeter and Grafana images are built and stored in a repo with this prefix.
# 6. Jmeter helm chart path.
# 7. Values template file path.
# 8. Values file path. This file is generated in the steps that follow.
# 9. Local port whose traffic is forwarded through SSH using kubectl to the Grafana dashboard.
# 10. Azure deployment file

sub=<YOUR-SUBSCRIPTION> && \
  location=southeastasia && \
  rgName=rg-aks-jmeter && \
  reporterStr=reporter && \
  repoPrefix=testframework && \
  jmeterChart="deployment/helm/aks-jmeter" && \
  valuesTemplate="$jmeterChart/values.yaml.template" && \
  valuesFile="$jmeterChart/values.yaml" && \
  localPort=5000 && \
  deploymentName=main
  bicep="deployment/bicep/$deploymentName.bicep"
```

2. Generate an SSH key pair (or use an existing one.)

```bash
ssh-keygen # Create an SSH key pair. (Skip if you already have one.)

sshPublicKey=$(cat <PATH-TO-PUBLIC-KEY>) # Example: ~/.ssh/id_rsa.pub
```

3. Login, select subscription and deploy test resources. The ACR and AKS names are obtained from the deployment output.

```bash
az login && \
  az account set -s $sub && \
  az group create -l $location -n $rgName

az deployment group create --resource-group $rgName --template-file $bicep --parameters sshPublicKey="$sshPublicKey"

deployment=$(az deployment group show --$rgName --name $deploymentName) && \
  aksName=$(echo $deployment | jq -r '.properties.outputResources[].id' | grep "managedClusters" | awk '{n=split($1,A,"/"); print A[n]}') && \
  acrName=$(echo $deployment | jq -r '.properties.outputResources[].id' | grep "registries/[a-z0-9]*$" | awk '{n=split($1,A,"/"); print A[n]}') && \
  acrLoginServer=$(az acr show -n $acrName | jq -r '.loginServer')
```

4. Build and push jmeter and reporter images.

```bash

# These image references are used in helm values.
# 1. Build and push jmeter controller.
# 2. Build and push jmeter worker.
# 3. Build and push grafana reporter.

az acr build --registry $acrName -t $repoPrefix/jmetercontroller:latest -f dockerfiles/jmeter-controller.DOCKERFILE dockerfiles/ && \
  az acr build --registry $acrName -t $repoPrefix/jmeterworker:latest -f dockerfiles/jmeter-controller.DOCKERFILE dockerfiles/ && \
  az acr build --registry $acrName -t $repoPrefix/reporter:latest -f dockerfiles/reporter.DOCKERFILE dockerfiles/
```

5. Connect to the cluster and verify kubectl is configured.

```bash
az aks get-credentials --resource-group $rgName --name $aksName && \
  kubectl cluster-info
```

6. Deploy the jmeter helm chart to get controller and worker pods up and running.

```bash

# 1. Generate a values.yaml file from the existing template. (The generated values.yaml file is gitignored.)
# 2. Review values.

sed "s/__REGISTRY__/$acrLoginServer/g" $valuesTemplate > $valuesFile && \
  helm show values $jmeterChart

# Install application.
# The TEST_* env variables are an example of how to pass parameters to your test plan
# through pod environment variables.
releaseName=test-1
helm install --set password="$TEST_ACR_PASSWORD" --set loginserver="$TEST_ACR_LOGINSERVER" --set username="$TEST_ACR_USERNAME" $releaseName $jmeterChart
```

7. Setup reporter: add datasource and dashboard.

* Well known default password in Grafana is `admin`: https://grafana.com/docs/grafana/v7.5/administration/configuration/#admin_password
* Grafana datasource API: https://grafana.com/docs/grafana/latest/http_api/data_source/#create-a-data-source
* Grafana dashboard API: https://grafana.com/docs/grafana/latest/http_api/dashboard/#create--update-dashboard

```bash
# 1. Create jmeter database in influxdb.
# 2. Copy datasource file.
# 3. POST datasource to grafana.
# 4. Copy dashboard file.
# 5. POST dashboard to grafana.

reporterPod=$(kubectl get pods | grep $reporterStr | awk '{print $1}') && \
  kubectl exec -it $reporterPod -- influx -execute 'CREATE DATABASE jmeter' && \
  kubectl cp grafana/datasource.json $reporterPod:/datasource.json && \
  kubectl exec -ti $reporterPod -- /bin/bash -c 'until [[ $(curl "http://admin:admin@localhost:3000/api/datasources" -X POST -H "Content-Type: application/json;charset=UTF-8" --data-binary @grafana/datasource.json) ]]; do sleep 5; done' && \
  kubectl cp grafana/dashboard.json $reporterPod:/dashboard.json && \
  kubectl exec -it $reporterPod -- curl 'http://admin:admin@localhost:3000/api/dashboards/db' -X POST -H 'Content-Type: application/json;charset=UTF-8' --data-binary '@grafana/dashboard.json'
```

8. Access Grafana dashboard.

  * Forward a local port to the grafana pod:
```bash
# Setup port forwarding to the grafana pod.
kubectl port-forward $reporterPod $localPort:3000
```

  * Access the dashboard at `http://localhost:$localPort>`.
    * The username and password are both `admin` by default, and you will be 
      prompted to update the password on first login.

  * Navigate to the dashboard titled "Testing Framework Dashboard" using the "Dashboard" tab on the top left.

### Run Jmeter test

TODO: summarize

1. Copy the jmx file to the controller pod.

```bash
# Copy test plan file to jmeter controller and start test.

controllerPod=$(kubectl get pod | grep jmeter-controller | awk '{print $1}') && \
  testName=acr && \
  kubectl cp jmeter/$testName.jmx $controllerPod:/$testName && \
  kubectl exec -it $controllerPod -- /bin/bash /load_test $testName
```
