# What

Terraform allows to transparently declare our infrastructure as code. Providing
a (non-official so far) plugin, we can provision vm the same way for our rocq
infra (proxmox)

# The road so far

## Prepare workstation

See prepare-workstation.md

## setup.sh

Create a `setup.sh` file holding the PM_{USER,PASS} information:

```
export PM_USER=<swh-login>@pam
export PM_PASS=<swh-login-pass>
```

source it in your current shell session.

```
source setup.sh
```

## provision new vm

```
terraform init
terraform apply
```

# Details

The provisioning is bootstraping vm declared in ".tf" files. It's using a base
template (debian-9-template, debian-10-template) installed in the hypervisor.
Instructions are detailed in the `init-template.md` file.

# Init

This initializes your local copy with the necessary:

```
terraform init
```

# Plan changes

Compulse all *.tf files present in the folder, then compute a
differential plan:

```
terraform plan
```

# Apply changes

Propose to apply the plan to the infra (interactively):

```
terraform apply
```
