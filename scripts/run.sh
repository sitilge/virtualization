#!/bin/sh

VIRT_DIR=/home/martins/Projects/virtualization

#use alsa driver for host audio
export QEMU_AUDIO_DRV=alsa
export QEMU_AUDIO_TIMER_PERIOD=0

qemu-system-x86_64 \
	-enable-kvm							`#enable the kvm hypervisor` \
	-machine type=pc,accel=kvm					`#use kvm on guest` \
	-m 8192								`#set the memory` \
	-cpu host,hv_relaxed,hv_spinlocks=0x1fff,hv_vapic,hv_time	`#match cpu to the one of the host, enable hyper-v enlightment for Windows guests` \
	-smp cores=4							`#assign more cpus` \
	-vga std 							`#std supports up to 2560x1600 without guest drivers` \
	-soundhw ac97							`#using motherboard audio, thus ac97` \
	`#use virtio drivers passthrough for networking` \
	-netdev user,id=vmnic \
	-device virtio-net,netdev=vmnic \
	`#attach the respective PCI devices` \
	-device vfio-pci,host=01:00.0,multifunction=on \
	-device vfio-pci,host=01:00.1 \
	`#passthrough mouse and kbd because of the terrible lag` \
	-device nec-usb-xhci,id=xhci0 \
	-device usb-host,bus=xhci0.0,vendorid=0x046d,productid=0xc31c \
	-device nec-usb-xhci,id=xhci1 \
	-device usb-host,bus=xhci1.0,vendorid=0x046d,productid=0xc05a \
	`#OVMF is an open-source UEFI firmware for QEMU virtual machines which provides better performance which allows PCI passthrough` \
	-drive file=/usr/share/ovmf/x64/OVMF_CODE.fd,if=pflash,format=raw \
	-drive file=/usr/share/ovmf/x64/OVMF_VARS.fd,if=pflash,format=raw \
	`#use virtio drivers instead of IDE to improve the performance. l2_cache_size = disk_size * 8 / cluster_size. The default cluster size is 64K` \
	-drive file=$VIRT_DIR/images/windows10.img,index=0,media=disk,format=qcow2,l2-cache-size=4M,if=virtio \
	-drive file=$VIRT_DIR/systems/windows10.iso,index=1,media=cdrom \
	-drive file=/usr/share/virtio/virtio-win.iso,index=2,media=cdrom \
