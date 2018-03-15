# Virtualization

A virtualization scripts for a Windows 10 guest machine

- Using `KVM` as the hypervisor and `QEMU` as the virtualizer.
- Using `qcow2` to allocate storage only when required by the guest.
- Memory must be set manually.
- Hyper-V enlightment is enabled specifically for Windows guest.
- Using `virtio` instead of IDE for speed improvements. Arch users can get them from AUR (`virtio-win`).
- L2 cache formula: l2_cache_size = disk_size * 8 / cluster_size, where cluster_size is 64K by default.
- The previous manual will be transfered here soon: [PCI_passthrough_via_OVMF/Examples](https://wiki.archlinux.org/index.php/PCI_passthrough_via_OVMF/Examples).
