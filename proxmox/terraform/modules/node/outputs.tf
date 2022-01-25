output "summary" {
  value = <<EOF

hostname: ${proxmox_vm_qemu.node.name}
fqdn: ${proxmox_vm_qemu.node.name}.${var.config["domain"]}
network: ${proxmox_vm_qemu.node.ipconfig0} macaddrs=${join(",", proxmox_vm_qemu.node.network[*]["macaddr"])}
vmid: ${proxmox_vm_qemu.node.vmid}
EOF

}
