#!/bin/bash

# JAHN:This is a hack for testing

# https://github.com/Azure/AKS/issues/611]

# Public IP address
# kubectl get svc istio-ingressgateway -n istio-system
IP="137.117.81.233"

# Name to associate with public IP address
DNSNAME="jahn-demo-aks-ingress"

# Get resource group and public ip name
RESOURCEGROUP=$(az network public-ip list --query "[?ipAddress!=null]|[?contains(ipAddress, '$IP')].[resourceGroup]" --output tsv)
PIPNAME=$(az network public-ip list --query "[?ipAddress!=null]|[?contains(ipAddress, '$IP')].[name]" --output tsv)

# Update public ip address with dns name
echo "IP            : $IP"
echo "DNSNAME       : $DNSNAME"
echo "RESOURCEGROUP : $RESOURCEGROUP"
echo "PIPNAME       : $PIPNAME"
az network public-ip update --resource-group $RESOURCEGROUP --name $PIPNAME --dns-name $DNSNAME
