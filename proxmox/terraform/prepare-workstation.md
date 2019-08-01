This is the required tooling for the following to work.

# terraform-provider-proxmox

go module to install

```
git clone https://github.com/Telmate/terraform-provider-proxmox
cd terraform-provider-proxmox

# compile terraform proxmox provider
export GOPATH=`pwd`
make setup
make
make install

# Install so that terrafor actually sees the plugin
mkdir -p ~/.terraform.d/plugins/linux_amd64
cp -v ./bin/* ~/.terraform.d/plugins/linux_amd64/
```

At the end of this, `terraform init` within /proxmox/terraform/ should now
work.

Doc: https://github.com/Telmate/terraform-provider-proxmox/blob/master/README.md

