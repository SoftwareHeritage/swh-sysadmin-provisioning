#!/bin/sh

# This script is used to attach data disk
# to for example node destined to be postgres replica

# node's name defined by the user
nodename=${1-"dbreplica1"}

# type of node (worker, db, etc...)
type=${2-"db"}

# resource group
resource_group="euwest-${type}"

# not a choice
location=westeurope

# disk's size in gb
disk_size=${3-1024}

# disk's name derivative from the vm we attach it too
disk_name="${nodename}_pgdata0"

# actually attach the disk
# this will create the disk if it does not exist
cmd="az vm disk attach \
   --resource-group ${resource_group} \
   --vm-name ${nodename} \
   --disk ${disk_name} \
   --size-gb ${disk_size} \
   --new"

echo $cmd
$cmd
