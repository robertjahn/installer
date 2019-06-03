#!/bin/bash

source ./deploymentArgument.lib
DEPLOYMENT=$1
validate_deployment_argument $DEPLOYMENT

# library with kubectl commands
source ./utils.sh

# validate environment variable values and read from creds.json if required
get_keptn_credentials_as_variables $DEPLOYMENT

case $DEPLOYMENT in
  aks)
    az aks get-credentials --resource-group $AZURE_RESOURCEGROUP --name $AZURE_CLUSTER_NAME --overwrite-existing
    if [[ $? != '0' ]]
    then
      exit 1
    fi
    ;;
  eks)
    echo "testConnection.sh: $DEPLOYMENT NOT SUPPORTED"
    exit 1
    ;;
  ocp)
    echo "testConnection.sh: $DEPLOYMENT NOT SUPPORTED"
    exit 1
    ;;
  gke)
    # Variables for creating cluster role binding
    if [[ -z "${GCLOUD_USER}" ]]; then
      print_debug "GCLOUD_USER is not set, retrieve it using gcloud."
      GCLOUD_USER=$(gcloud config get-value account)
      if [[ $? != 0 ]]; then
        print_error "gloud failed to get account values." && exit 1
      fi
      verify_variable "$GCLOUD_USER" "GCLOUD_USER is not defined in environment variable nor could it be retrieved using gcloud." 
    fi

    # Grant cluster admin rights to gcloud user
    # TODO create vs apply
    kubectl create clusterrolebinding keptn-cluster-admin-binding --clusterrole=cluster-admin --user=$GCLOUD_USER
    verify_kubectl $? "Cluster role binding could not be created."

    gcloud --quiet config set project $GKE_PROJECT
    gcloud --quiet config set container/cluster $CLUSTER_NAME
    gcloud --quiet config set compute/zone $CLUSTER_ZONE
    gcloud container clusters get-credentials $CLUSTER_NAME --zone $CLUSTER_ZONE --project $GKE_PROJECT
    if [[ $? != '0' ]]
    then
      exit 1
    fi
    ;;
  *)
    echo "testConnection.sh: ERROR: INVALID DEPLOYMENT TYPE"
    exit 1      
    ;;
esac

