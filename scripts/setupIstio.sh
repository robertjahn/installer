#!/bin/bash
CLUSTER_IPV4_CIDR=$1
SERVICES_IPV4_CIDR=$2

source ./utils.sh

case $DEPLOYMENT in
  aks)
    kubectl apply --filename https://github.com/knative/serving/releases/download/v0.4.0/istio-crds.yaml
    verify_kubectl $? "Error applying Istio Credentials"
    kubectl apply --filename https://github.com/knative/serving/releases/download/v0.4.0/istio.yaml
    verify_kubectl $? "Error applying Istio"
    kubectl label namespace default istio-injection=enabled --overwrite=true
    verify_kubectl $? "Error setting istio-injection flag "
    wait_for_all_pods_in_namespace "istio-system"
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
    # Apply custom resource definitions for Istio
    kubectl apply -f ../manifests/istio/istio-crds-knative.yaml
    verify_kubectl $? "Creating istio custom resource definitions failed."
    wait_for_crds "virtualservices,destinationrules,serviceentries,gateways,envoyfilters,policies,meshpolicies,httpapispecbindings,httpapispecs,quotaspecbindings,quotaspecs,rules,attributemanifests,bypasses,circonuses,deniers,fluentds,kubernetesenvs,listcheckers,memquotas,noops,opas,prometheuses,rbacs,redisquotas,servicecontrols,signalfxs,solarwindses,stackdrivers,statsds,stdios,apikeys,authorizations,checknothings,kuberneteses,listentries,logentries,edges,metrics,quotas,reportnothings,servicecontrolreports,tracespans,adapters,instances,templates,handlers,rbacconfigs,serviceroles,servicerolebindings"

    # Apply Istio configuration
    rm -f ../manifests/gen/istio-knative.yaml
    cat ../manifests/istio/istio-knative.yaml | \
    sed 's~INCLUDE_OUTBOUND_IP_RANGES_PLACEHOLDER~'"$CLUSTER_IPV4_CIDR,$SERVICES_IPV4_CIDR"'~' >> ../manifests/gen/istio-knative.yaml

    kubectl apply -f ../manifests/gen/istio-knative.yaml
    verify_kubectl $? "Creating all istio components failed."
    wait_for_all_pods_in_namespace "istio-system"
    ;;
  *)
    echo "ERROR: INVALID DEPLOYMENT TYPE: $DEPLOYMENT"
    exit 1      
    ;;
esac

# Delete all pods in keptn to apply Istio changes
kubectl delete pods --all -n keptn
verify_kubectl $? "Deleting pods in keptn namespace failed."

# JAHN - this will fail since no pods
#wait_for_all_pods_in_namespace "keptn"

# # ##############################################
# # ## Start validation of Istio installation   ##
# # ##############################################

# # Wait max 4min for IP of Istio ingressgateway
# # sleep 2
# # RETRY=0
# # while [ $RETRY -lt 24 ]
# # do
# #   ISTIO_INGRESS_IP=$(kubectl -n istio-system get service istio-ingressgateway -o jsonpath='{.status.loadBalancer.ingress[0].ip}')
# #   if [[ -z "${ISTIO_INGRESS_IP}" ]]
# #   then
# #     echo "[keptn|DEBUG] IP of Istio ingressgateway: ${ISTIO_INGRESS_IP}"
# #     echo "[keptn|INFO] IP of Istio ingressgateway available, can continue... "
# #     break
# #   fi
# #   RETRY=$[$RETRY+1]
# #   echo "[keptn|INFO] Retry: ${RETRY}/24 - Wait 10s for changes to apply... "
# #   sleep 10
# # done
