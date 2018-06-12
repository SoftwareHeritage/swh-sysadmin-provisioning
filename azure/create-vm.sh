#!/bin/sh

worker=${1-worker01}
zone=westeurope
resource_prefix=euwest
resource_group="${resource_prefix}-workers"
image=credativ:Debian:9:latest
# pub_key=~/.ssh/id-rsa-swhworker.pub
pub_key=~/.ssh/id_rsa.inria.pub

# "default" subnet in the "swh-vnet" virtual network of the "swh-resource" resource group
subnet=/subscriptions/49b7f681-8efc-4689-8524-870fc0c1db09/resourceGroups/swh-resource/providers/Microsoft.Network/virtualNetworks/swh-vnet/subnets/default

# Change for virtual machine size. Standard_DS = SSD; Standard_S = Standard disk
# size=Standard_DS11_v2
size=Standard_DS2_v2

# SSD
disk_group="${resource_prefix}workersdisks"
# Standard
# disk_group="${resource_prefix}stddisks"

diagnostics_resource=swhresourcediag966

azure vm create \
      --resource-group "${resource_group}" \
      --name "${worker}-${resource_prefix}" \
      --location "${zone}" \
      --os-type Linux \
      --image-urn "${image}" \
      --subnet-id "${subnet}" \
      --nic-name "${worker}-${resource_prefix}-if" \
      --user testadmin \
      --ssh-publickey-file "${pub_key}" \
      --storage-account-name "${disk_group}" \
      --vm-size "${size}" \
      --boot-diagnostics-storage-uri "http://${diagnostics_resource}.blob.core.windows.net/"
