This is the required tooling for the following to work.

# proxmox

Current supported version is 13.5 from debian stable

```
$ cat /etc/apt/preferences.d/terraform
Package: terraform
Pin: version 0.13.*
Pin-Priority: 999
```

# terraform-provider-proxmox

go module to install

```
git clone https://github.com/Telmate/terraform-provider-proxmox
cd terraform-provider-proxmox

# compile terraform proxmox provider
make

# Install so that terraform actually sees the plugin
mkdir -p ~/.terraform.d/plugins/local/telmate/proxmox/0.0.1/linux_amd64
cp -v ./bin/* ~/.terraform.d/plugins/local/telmate/proxmox/0.0.1/linux_amd64
```

At the end of this, `terraform init` within /proxmox/terraform/ should now
work.

Doc: https://github.com/Telmate/terraform-provider-proxmox/blob/master/README.md
