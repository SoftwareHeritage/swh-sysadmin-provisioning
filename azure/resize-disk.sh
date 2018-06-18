# This script is used to attach data disk
# to for example node destined to be postgres replica

# node's name defined by the user
nodename=${1-"dbreplica1"}

# type
type=${2-"db"}

# resource group
resource_group="euwest-${type}"

# not a choice
location=westeurope

# disk's size in gb
disk_size=${3-2048}

# type of node (worker, db, etc...)
disk_name="${nodename}_pgdata0"

# deallocate the vm (stop, deallocate)
cmd="az vm deallocate \
    --resource-group ${resource_group} \
    --name ${nodename}"
echo $cmd
$cmd

# update the disk
cmd="az disk update \
   --resource-group ${resource_group} \
   --name ${disk_name} \
   --size-gb ${disk_size}"

echo $cmd
$cmd
