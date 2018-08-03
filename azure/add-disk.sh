#!/bin/sh

# This script is used to attach data disk
# to for example node destined to be postgres replica

# node's name defined by the user
nodename=${1-"dbreplica1"}

# type of node (worker, db, etc...)
type=${2-"db"}

# not a choice
resource_prefix="euwest"
location=westeurope

full_nodename="${nodename}-${resource_prefix}"

# Depending on the types, we compute the resource group
# worker, db, storage have dedicated shared resource group
# other can be specifically tailored for them
if [ $type = 'worker' ]; then   # for workers, it's a shared resource
    resource_group="${resource_prefix}-${type}s"
elif [ $type = 'db' ]; then     # for dbs as well
    resource_group="${resource_prefix}-${type}"
    full_nodename="${nodename}"
elif [ $type = 'storage' ]; then
    resource_group="${resource_prefix}-server"
else # for other node types (webapp), that is specifically tailored for
    resource_group="${resource_prefix}-${nodename}"
fi

# disk's size in gb
disk_size=${3-1024}

# disk's name derivative from the vm we attach it too
disk_name="${nodename}_pgdata0"

# actually attach the disk
# this will create the disk if it does not exist
cmd="az vm disk attach \
   --resource-group ${resource_group} \
   --vm-name ${full_nodename} \
   --disk ${disk_name} \
   --size-gb ${disk_size} \
   --new"

echo $cmd
$cmd
