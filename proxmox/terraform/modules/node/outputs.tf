output summary {
    value = <<EOF

hostname: ${proxmox_vm_qemu.node.name}
fqdn: ${proxmox_vm_qemu.node.name}.${var.config["domain"]}
network: ${proxmox_vm_qemu.node.ipconfig0} macaddr=${lookup(proxmox_vm_qemu.node.network[0], "macaddr")}
EOF
}
