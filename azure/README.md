SWH azure provisioning
-------------------------

# Pre-requisite

- az [1]
- rights in the azure portal [2]

[1] https://docs.microsoft.com/en-us/cli/azure/install-azure-cli-apt?view=azure-cli-latest
[2] https://portal.azure.com

# Create vm

``` sh
$ ./create-vm.sh <name> <type> <location>
# create a node with name `name` and `type` at `location`
# ...
$ ./create-vm.sh worker01 worker euwest
# creates a node worker01.euwest.azure of type `worker` at location `euwest` (default)
# ...
$ ./create-vm.sh webapp0 webapp
# creates a node webapp0 of type `something-different-than-worker-type`
# at location euwest
```

Example name:
- worker01
- webapp0
- dbreplica0

This will:
- create an azure vm node
- running the latest debian stable (9 as of this writing)
- with admin user zack (uid 1000)
- with a local public key (so that we can connect later on)
- and continue the provisioning steps

# Provision

``` sh
ADMIN_USER=zack
scp ./provision-vm.sh $ADMIN_USER@<name>:
ssh $ADMIN_USER@<name> ./provision-vm.sh <public-or-private-nature>
```

# More documentation

cf. [New machine setup](https://wiki.softwareheritage.org/index.php?title=New_machine_setup)
