SWH azure provisioning
-------------------------

# Pre-requisite

- az [1]
- rights in the azure portal [2]

[1] https://docs.microsoft.com/en-us/cli/azure/install-azure-cli-apt?view=azure-cli-latest
[2] https://portal.azure.com

Note: `azure-cli` is actually a Python package, so it can also be installed in
a virtualenv (preferably a frech dedicated one, since it pulls something like
130 packages.):

``` sh
$ mkvirtualenv -p /usr/bin/python3 -a $PWD azure
(azure) $
```

# Create vm

``` sh
$ ./create-vm.sh <name> <type> <location>
# create a node with name `name` and `type` at `location`
# ...
$ ./create-vm.sh worker01 worker euwest
# creates a node worker01.euwest.azure of type `worker` at location `euwest` (default)
# ...
$ ./create-vm.sh dbreplica1 db
# creates a node webapp0 of type `db` at location euwest
# ...
```

Possible names:
- worker01
- webapp0
- dbreplica0


Possible types:
- db (replica or otherwise)
- storage (stoarge service)
- worker (computing nodes)
- webapp


This will:
- create an azure vm node
- running the latest debian stable (9 as of this writing)
- with admin user zack (uid 1000)
- with a local public key (so that we can connect later on)
- and continue the provisioning steps

# Provision

``` sh
ADMIN_USER=zack
scp ./provision-vm.sh $ADMIN_USER@<name>:/tmp/
# check the ip and access the vm
ssh $ADMIN_USER@<ip>
$ chmod +x /tmp/provision-vm.sh
$ sudo /tmp/provision-vm.sh (public|private)
# ...
# Use Example:
# machine destined to be publicly accessible
$ sudo /tmp/provision-vm.sh public
# ...
# machine destined to be only seen through our vpn
$ sudo /tmp/provision-vm.sh private
```

# update DNS server

Trigger a record refresh on the dns server (pergamon)

``` sh
$ sudo puppet agent --test
```

# More documentation

cf. [New machine setup](https://wiki.softwareheritage.org/index.php?title=New_machine_setup#Setting_up_a_new_Virtual_Machine_.28semi-manual_process.29)
