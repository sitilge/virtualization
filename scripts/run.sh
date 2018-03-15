#!/bin/sh

VIRT_DIR=~/Projects/virtualization

qemu-system-x86_64 \
	-enable-kvm							`#enable the kvm hypervisor` \
	-machine type=pc,accel=kvm					`#use kvm on guest` \
	-m 4096								`#set the memory` \
	-cpu host,hv_relaxed,hv_spinlocks=0x1fff,hv_vapic,hv_time	`#match cpu to the one of the host, enable hyper-v enlightment for Windows guests` \
	-vga std							`#std supports up to 2560x1600 without guest drivers` \
	`#Using virtio instead of IDE to improve the performance. l2_cache_size = disk_size * 8 / cluster_size. The default cluster size is 64K` \
	-drive file=$VIRT_DIR/images/windows10.img,index=0,media=disk,format=qcow2,l2-cache-size=4M,if=virtio \
	-drive file=$VIRT_DIR/systems/windows10.iso,index=2,media=cdrom \
	-drive file=/usr/share/virtio/virtio-win.iso,index=3,media=cdrom
