output "summary" {
  value = <<EOF

hostname: ${proxmox_vm_qemu.node.name}
fqdn: ${proxmox_vm_qemu.node.name}.${var.config["domain"]}
network: ${proxmox_vm_qemu.node.ipconfig0}
EOF

}
