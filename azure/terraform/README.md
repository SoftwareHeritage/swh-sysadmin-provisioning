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

Note: It might be a good idea to change the `variables.tf` file to adapt for
example the admin user and its associated public key

# Apply changes

Same as previous command except that it applies the diff to the infra:

```
terraform apply
```
