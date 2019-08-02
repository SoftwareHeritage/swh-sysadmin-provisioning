output name {
    value = "${proxmox_vm_qemu.node.name}"
}

output ip {
    value = "${proxmox_vm_qemu.node.network.*.ip}"
}

output macaddr {
    value = "${proxmox_vm_qemu.node.network.*.macaddr}"
}
