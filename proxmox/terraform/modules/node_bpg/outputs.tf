output "summary" {
  value = <<EOF

hostname: ${proxmox_virtual_environment_vm.node.name}
fqdn: ${proxmox_virtual_environment_vm.node.name}.${var.config["domain"]}
network: ${proxmox_virtual_environment_vm.node.initialization[0].ip_config[0].ipv4[0].address}
EOF
}