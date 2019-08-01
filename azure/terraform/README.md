# What

Terraform allows to transparently declare our infrastructure as code.


# The road so far

Only the vault is defined within the `vault.tf` file.

Vault is composed of:
- one api allowing to request object cooking or retrieve cooked objects
  (objstorage, db)
- this also uses a storage to read the swh archive (azure:
  storage0.euwest.azure)

The vault.tf defines here:
- existing:
  - subnet (reuse)
  - security-group (reuse)
- new resource:
  - euwest-vault: to group together the allocated resource for the vault
  - vangogh-interface: to define an ip for the new server vangogh
  - vault-storage: storage account for the BlobStorage necessary for the
    objstorage api of the vault (including a container "contents" to actually
    store the blobs)
  - vault-server: the 'vangogh.euwest.azure' vm to actually serve the vault api

# Install terraform

https://learn.hashicorp.com/terraform/getting-started/install.html#installing-terraform

# Login

Through azure cli (for now)

```
az login
```

# Init

```
terraform init
```

# Plan changes

This will compute all *.tf files present in the folder and compute a
differential plan:

```
terraform plan
```

# Apply changes

Same as previous command except that it applies the diff to the infra
(interactive):

```
terraform apply
```

Note: adapt the `init.tf` file with the admin user's associated public key
first. That will allow you to connect (ssh) to the new nodes you created (if
any).

# Arborescence

- init.tf: Common resources in our azure infrastructure
- vault.tf: Vault node definition
