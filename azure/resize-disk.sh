# This script is used to attach data disk
# to for example node destined to be postgres replica

# node's name defined by the user
nodename=${1-"dbreplica1"}

# type
type=${2-"db"}

# disk's size in gb
disk_size=${3-2048}

# not a choice
resource_prefix="euwest"
location=westeurope
resource_group="euwest-${type}"

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

# disk's name
disk_name="${nodename}_pgdata0"

# deallocate the vm (stop, deallocate)
cmd="az vm deallocate \
    --resource-group ${resource_group} \
    --name ${full_nodename}"
echo $cmd
$cmd

# update the disk
cmd="az disk update \
   --resource-group ${resource_group} \
   --name ${disk_name} \
   --size-gb ${disk_size}"

echo $cmd
$cmd
