#!/bin/bash

cp /usr/share/edk2.git/ovmf-x64/OVMF_VARS-pure-efi.fd /tmp/OVMF_VARS-pure-efi.fd

qemu-system-x86_64 \
  -enable-kvm \
  -m 8196 \
  -smp cores=4,threads=1 \
  -cpu host,kvm=off \
  -vga none \
  -soundhw hda \
  -device hda-micro \
  -usb -usbdevice host:046d:c077 -usbdevice host:046d:c31c \
  -device vfio-pci,host=01:00.0,multifunction=on \
  -device vfio-pci,host=01:00.1 \
  -drive if=pflash,format=raw,readonly,file=/usr/share/edk2.git/ovmf-x64/OVMF_CODE-pure-efi.fd \
  -drive if=pflash,format=raw,file=/tmp/OVMF_VARS-pure-efi.fd \
  -device virtio-scsi-pci,id=scsi \
  -drive file=./../windows/Win10_1607_N_English_x64.iso,id=isocd,format=raw,if=none -device scsi-cd,drive=isocd \
  -drive file=/home/martins/Desktop/arch.iso,id=archcd,format=raw,if=none -device ide-cd,bus=ide.1,drive=archcd \
  -drive file=./../images/Win10_1607_N_English_x64.img,id=disk,format=qcow2,if=none,cache=writeback -device scsi-hd,drive=disk \
  -drive file=./../virtio/virtio-win-0.1.130.iso,id=virtiocd,if=none,format=raw -device ide-cd,bus=ide.1,drive=virtiocd
