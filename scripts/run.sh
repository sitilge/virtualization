#!/bin/sh

VIRT_DIR=/home/martins/Projects/virtualization

qemu-system-x86_64 \
	-enable-kvm							`#enable the kvm hypervisor` \
	-machine type=pc,accel=kvm					`#use kvm on guest` \
	-m 8192								`#set the memory` \
	-cpu host,hv_relaxed,hv_spinlocks=0x1fff,hv_vapic,hv_time	`#match cpu to the one of the host, enable hyper-v enlightment for Windows guests` \
	-vga std 							`#std supports up to 2560x1600 without guest drivers` \
	`#OVMF is an open-source UEFI firmware for QEMU virtual machines which provides better performance which allows PCI passthrough` \
	-drive file=/usr/share/ovmf/x64/OVMF_CODE.fd,if=pflash,format=raw \
	-drive file=/usr/share/ovmf/x64/OVMF_VARS.fd,if=pflash,format=raw \
	`#using virtio instead of IDE to improve the performance. l2_cache_size = disk_size * 8 / cluster_size. The default cluster size is 64K` \
	-drive file=$VIRT_DIR/images/windows10.img,index=0,media=disk,format=qcow2,l2-cache-size=4M,if=virtio \
	-drive file=$VIRT_DIR/systems/windows10.iso,index=1,media=cdrom \
	-drive file=/usr/share/virtio/virtio-win.iso,index=2,media=cdrom \
	`#attaching the respective PCI devices` \
	-device vfio-pci,host=01:00.0,multifunction=on \
	-device vfio-pci,host=01:00.1 \
