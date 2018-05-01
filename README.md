# Virtualization

Virtualization scripts and config for arch linux hosts and Win 10 guests using KVM, QEMU, VFIO and OVMF.

## Hardware

- OS: arch linux running `linux-vfio` kernel.
- CPU: Intel i5 6600K.
- GPU: Gigabyte Radeon RX 460.
- Mobo: Asus Z170i.
- Storage: Samsung 850 EVO 500GB.
- Memory: 16GB Corsair DDR4.
- Monitor: LG 23EA63.

## Software

- `linux-vfio`
- `qemu` or `qemu-git` (recommended)
- `virtio-win`
- `ovmf`

## Notes

- You can easy simlink the config files using `stow -t / boot mkinitcpio` and then `mkinitcpio -p linux-vfio`.
- `-smp cores=4` - guest might utilize only one core otherwise.
- `-soundhw ac97` - I'm passing mobo audio thus ac97. Download, unzip and install the Realtek AC97 drivers within a guest.
- Use `virtio` drivers for both block devices and network. For example, the ping went down from 250 to 50.
- Mouse and keyboard passthrough solved the terrible lag problem which was present in emulation mode.
- Make sure virtualization is supported and enabled in your firmware (UEFI). The option was hidden in a submenu in my case.
- As trivial as it sounds, check your cables. Twice.
- Be patient - it took more than 10 minutes for the guest to recognize the GPU.
