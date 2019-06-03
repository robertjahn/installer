#!/bin/bash

LOG_LOCATION=./logs
exec > >(tee -i $LOG_LOCATION/installKeptn.log)
exec 2>&1

# shared library parsing deployment argument
source ./deploymentArgument.lib
DEPLOYMENT=$1
validate_deployment_argument $DEPLOYMENT

# shared library for the keptn installation
source ./utils.sh

# validate environment variable values and read from creds.json if required
get_keptn_credentials_as_variables

print_info "Starting installation of keptn for: $DEPLOYMENT_NAME"

# setup Kubectl client credentials
./testConnection.sh
if [[ $? != '0' ]]; then
  exit 1
else
  print_info "Kubectl connection to cluster successful"
fi

# Test kubectl get namespaces
verify_kubectl_connection

# Create K8s namespaces
kubectl apply -f ../manifests/keptn/keptn-namespace.yml
verify_kubectl $? "Creating keptn namespace failed."

# JAHN:Skipping this step
## Create container registry
#print_info "Creating container registry"
#./setupContainerRegistry.sh
#verify_install_step $? "Creating container registry failed."
#print_info "Creating container registry done"

# Variables for installing Istio and Knative
if [[ -z "${CLUSTER_IPV4_CIDR}" ]]; then
  print_debug "CLUSTER_IPV4_CIDR is not set, retrieving it"
  case $DEPLOYMENT in
  aks)
    CLUSTER_IPV4_CIDR=$(az aks show --name ${AZURE_CLUSTER_NAME} --resource-group ${AZURE_RESOURCEGROUP} | jq -r '.networkProfile.podCidr')
    ;;
  eks)
    echo "$DEPLOYMENT NOT SUPPORTED"
    exit 1
    ;;
  ocp)
    echo "$DEPLOYMENT NOT SUPPORTED"
    exit 1
    ;;
  gke)
    CLUSTER_IPV4_CIDR=$(gcloud container clusters describe ${CLUSTER_NAME} --zone=${CLUSTER_ZONE} | yq r - clusterIpv4Cidr)
    ;;
  *)
    echo "ERROR: INVALID DEPLOYMENT TYPE"
    exit 1      
    ;;
  esac
  if [[ $? != 0 ]]; then
    print_error "Failed to describe the ${CLUSTER_NAME} cluster for retrieving the ${CLUSTER_IPV4_CIDR} property." && exit 1
  fi
  verify_variable "$CLUSTER_IPV4_CIDR" "CLUSTER_IPV4_CIDR is not defined in environment variable nor could it be retrieved." 
fi

if [[ -z "${SERVICES_IPV4_CIDR}" ]]; then
  print_debug "SERVICES_IPV4_CIDR is not set, is not set, retrieving it"
  case $DEPLOYMENT in
    aks)
      SERVICES_IPV4_CIDR=$(az aks show --name ${AZURE_CLUSTER_NAME} --resource-group ${AZURE_RESOURCEGROUP} | jq -r '.networkProfile.serviceCidr')
      ;;
    eks)
      echo "$DEPLOYMENT NOT SUPPORTED"
      exit 1
      ;;
    ocp)
      echo "$DEPLOYMENT NOT SUPPORTED"
      exit 1
      ;;
    gke)
      SERVICES_IPV4_CIDR=$(gcloud container clusters describe ${CLUSTER_NAME} --zone=${CLUSTER_ZONE} | yq r - servicesIpv4Cidr)
      ;;
    *)
      echo "ERROR: INVALID DEPLOYMENT TYPE"
      exit 1      
      ;;
  esac
  if [[ $? != 0 ]]; then
    print_error "Failed to describe the ${CLUSTER_NAME} cluster for retrieving the ${SERVICES_IPV4_CIDR} property." && exit 1
  fi
  verify_variable "$SERVICES_IPV4_CIDR" "SERVICES_IPV4_CIDR is not defined in environment variable nor could it be retrieved" 
fi

print_debug "CLUSTER_IPV4_CIDR: $CLUSTER_IPV4_CIDR"
print_debug "SERVICES_IPV4_CIDR: $SERVICES_IPV4_CIDR"

# Install Istio service mesh
print_info "Installing Istio"
./setupIstio.sh $CLUSTER_IPV4_CIDR $SERVICES_IPV4_CIDR
verify_install_step $? "Installing Istio failed."
print_info "Installing Istio done"

# Install knative core components
print_info "Installing Knative"
./setupKnative.sh $CLUSTER_IPV4_CIDR $SERVICES_IPV4_CIDR
verify_install_step $? "Installing Knative failed."
print_info "Installing Knative done"

# Install keptn core services - Install keptn channels
print_info "Installing keptn"
./setupKeptn.sh
verify_install_step $? "Installing keptn failed."
print_info "Installing keptn done"

# Install keptn services
print_info "Wear uniform"
./wearUniform.sh
verify_install_step $? "Installing keptn's uniform failed."
print_info "Keptn wears uniform"

# Install done
print_info "Installation of keptn complete."

# Retrieve keptn endpoint and api-token
KEPTN_ENDPOINT=https://$(kubectl get ksvc -n keptn control -o=yaml | yq r - status.domain)
KEPTN_API_TOKEN=$(kubectl get secret keptn-api-token -n keptn -o=yaml | yq - r data.keptn-api-token | base64 --decode)

print_info "keptn endpoint: $KEPTN_ENDPOINT"
print_info "keptn api-token: $KEPTN_API_TOKEN"

#print_info "To retrieve the keptn API token, please execute the following command:"
#print_info "kubectl get secret keptn-api-token -n keptn -o=yaml | yq - r data.keptn-api-token | base64 --decode"
