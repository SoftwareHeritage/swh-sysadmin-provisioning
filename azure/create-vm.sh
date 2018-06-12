#!/bin/sh

# node's name defined by the user
nodename=${1-"worker01"}

# type of nodes:
# - worker
# - other things (dbreplica, webapp, etc...)
type=${2-"worker"}

# where to install this (not expected to change though)
resource_prefix=${3-"euwest"}

# Per type, we can decide to override the resource_group
if [ $type = 'worker' ]; then
    resource_suffix='workers'
else
    resource_suffix=$nodename
fi

# Depending on the types, we compute the resource group
# for workers, it's a shared resource
# for other nodes, that is specifically tailored for
# feel free to adapt the policy though
resource_group="${resource_prefix}-${resource_suffix}"

location=westeurope

# Image we create the node from
image=credativ:Debian:9:latest
# Using the user's default public key for ssh connection
pub_key=~/.ssh/id_rsa.pub

# "default" subnet in the "swh-vnet" virtual network of the "swh-resource" resource group
subnet=/subscriptions/49b7f681-8efc-4689-8524-870fc0c1db09/resourceGroups/swh-resource/providers/Microsoft.Network/virtualNetworks/swh-vnet/subnets/default

# Change for virtual machine size.
# - Standard_DS = SSD;
# - Standard_S = Standard disk.
# Use `az vm list-sizes -l westeurope -o table` to list allowed VM
# types
vm_type="Standard_DS2_v2"
# vm_type=Standard_DS11_v2
# vm_type="Standard_B2ms"

# boot diagnostic storage resource
diagnostics_resource=swhresourcediag966

# zack is the uid 1000 in our manifest using it simplifies the
# creation and removes the otherwise necessary steps to remove that
# user
admin_user=zack

az vm create \
   --name "${nodename}-${resource_prefix}" \
   --resource-group "${resource_group}" \
   --location "${location}" \
   --image "${image}" \
   --size "${vm_type}" \
   --subnet "${subnet}" \
   --admin-username "${admin_user}" \
   --ssh-key-value "${pub_key}" \
   --boot-diagnostics-storage "http://${diagnostics_resource}.blob.core.windows.net/"
