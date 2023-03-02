# What

Terraform allows to transparently declare our infrastructure as code. Providing
a (non-official so far) plugin, we can provision vm the same way for our rocq
infra (proxmox)

## Prepare workstation

See prepare-workstation.md

## Get rancher access key
Go to rancher, in your account detail[1] generate a new access key without scope

[1] https://rancher.euwest.azure.internal.softwareheritage.org/dashboard/account

## setup.sh

Create a `setup.sh` file holding the PM_{USER,PASS} information:

```
export PM_USER=<swh-login>@pam
export PM_PASS=<swh-login-pass>
export RANCHER_ACCESS_KEY="<rancher token id>"
export RANCHER_SECRET_KEY="<rancher secret key>"
```

source it in your current shell session.

```
source setup.sh
```

## provision infra

```
cd production  # or staging
terraform init
terraform apply
```

# Details

The provisioning is bootstraping vms declared in ".tf" files (in dependency
order if any).

It's using a base template (either debian-9-template, debian-10-template)
installed in the hypervisor. Instructions are detailed in the
`init-template.md` file.

## Init

This initializes your local copy with the necessary:

```
terraform init
```

## Plan changes

Parse all *.tf files present in the folder, then compute a differential plan:

```
terraform plan
```

## Apply changes

Propose to apply the plan to the infra (interactively):

```
terraform apply
```

## Upgrade a provider

- Change the version in `version.tf`
- Apply the changes

```
terraform init --upgrade
```
- test the new version in each `staging`, `admin` and `production` directories

```
terraform refresh
terraform plan
```

- Adapt / fix the configuration to have no changes to apply

Examples of expected result for staging:
```
terraform/staging$ terraform refresh
...(ensure there are no errors)...

terraform/staging$ terraform plan
module.webapp.proxmox_vm_qemu.node: Refreshing state... [id=pompidou/qemu/119]
module.counters0.proxmox_vm_qemu.node: Refreshing state... [id=pompidou/qemu/138]
module.poc-rancher-sw1.proxmox_vm_qemu.node: Refreshing state... [id=uffizi/qemu/134]
module.rp0.proxmox_vm_qemu.node: Refreshing state... [id=pompidou/qemu/129]
module.poc-rancher-sw0.proxmox_vm_qemu.node: Refreshing state... [id=uffizi/qemu/135]
module.search-esnode0.proxmox_vm_qemu.node: Refreshing state... [id=pompidou/qemu/130]
module.search0.proxmox_vm_qemu.node: Refreshing state... [id=pompidou/qemu/131]
module.worker3.proxmox_vm_qemu.node: Refreshing state... [id=pompidou/qemu/137]
module.worker1.proxmox_vm_qemu.node: Refreshing state... [id=pompidou/qemu/118]
module.mirror-test.proxmox_vm_qemu.node: Refreshing state... [id=uffizi/qemu/132]
module.objstorage0.proxmox_vm_qemu.node: Refreshing state... [id=pompidou/qemu/102]
module.deposit.proxmox_vm_qemu.node: Refreshing state... [id=pompidou/qemu/120]
module.scheduler0.proxmox_vm_qemu.node: Refreshing state... [id=pompidou/qemu/116]
module.worker2.proxmox_vm_qemu.node: Refreshing state... [id=pompidou/qemu/112]
module.poc-rancher.proxmox_vm_qemu.node: Refreshing state... [id=uffizi/qemu/114]
module.worker0.proxmox_vm_qemu.node: Refreshing state... [id=pompidou/qemu/117]
module.vault.proxmox_vm_qemu.node: Refreshing state... [id=pompidou/qemu/121]

No changes. Your infrastructure matches the configuration.

Terraform has compared your real infrastructure against your configuration and found no differences, so no changes are needed.
```
