# Virtualization

Virtualization scripts for linux hosts.

- Using `KVM` as the hypervisor and `QEMU` as the virtualizer.
- Using `qcow2` to allocate storage only when required by the guest.
- Memory must be set manually.
- Hyper-V enlightment is enabled specifically for Windows guest.
- Using `virtio` instead of IDE for speed improvements. Arch users can get the drivers from AUR (`virtio-win`).
- L2 cache formula: l2_cache_size = disk_size * 8 / cluster_size, where cluster_size is 64K by default.
- See this post for kernel parameters if nested virtualization is required: [Nested Virtualization](https://ladipro.wordpress.com/2017/02/24/running-hyperv-in-kvm-guest)
