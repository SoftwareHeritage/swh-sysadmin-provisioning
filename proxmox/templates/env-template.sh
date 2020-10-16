export PROXMOX_USER=myuser@pam
export PROXMOX_PASSWORD=mysecretpassword
export PROXMOX_URL=https://branly.internal.softwareheritage.org:8006/api2/json
export PROXMOX_NODE=branly

# URL where the vm could reach the local http server started by packer
export HTTP_SERVER_URL=http://branly.internal.softwareheritage.org:8888

# Build environment
export TEMPLATE_IP=192.168.100.214
export TEMPLATE_NETMASK=255.255.255.0
export TEMPLATE_GW=192.168.100.1
export TEMPLATE_NS=192.168.100.29
