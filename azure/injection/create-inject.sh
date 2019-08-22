#!/bin/sh

# Script used to boostrap the injection of our objstorage to azure

set -e

group="swh-injection"

location="westeurope"

vm_name="$1"

vm_size="Standard_DS5_v2"
vm_subnet="/subscriptions/49b7f681-8efc-4689-8524-870fc0c1db09/resourceGroups/swh-resource/providers/Microsoft.Network/virtualNetworks/swh-vnet/subnets/default"
vm_nsg=""

vm_user="injection"
vm_sshkey="~/.ssh/id_rsa.inria.pub"

vm_ndisks=12

if ! az group show "$group" >/dev/null; then
    az group create "$group" "$location"
fi

azure vm create \
      --resource-group "${group}" \
      --name "${vm_name}" \
      --size "${vm_size}" \
      -y Linux \
      --image credativ:Debian:9:latest \
      --nsg "${vm_nsg}" \
      -S "${vm_subnet}" \
      -f "${vm_name}-if" \
      -i "${vm_name}-public" --public-ip-domain-name "swh${vm_name}" --public-ip-idletimeout 30 \
      -u "${vm_user}" -M "${vm_sshkey}" \

for disk in $(seq 1 "${vm_ndisks}"); do
    az vm disk attach \
          --new \
          -g "${group}" \
          --vm-name "${vm_name}" \
          --size-gb 1024 \
          --disk "${vm_name}-data${disk}"
done

vm_hostname="swh${vm_name}.${location}.cloudapp.azure.com"
scp -i "${vm_sshkey}" provision-inject.sh "${vm_user}@${vm_hostname}:"
ssh -i "${vm_sshkey}" "${vm_user}@${vm_hostname}" sudo bash provision-inject.sh
