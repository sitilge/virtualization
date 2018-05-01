#!/bin/sh

VIRT_DIR=/home/martins/Projects/virtualization

qemu-img create \
	-f qcow2				`#only allocate size when the guest needs it` \
	-o lazy_refcounts=on 			`#improve cache speed` \
	${VIRT_DIR}/images/windows10.img 64G
