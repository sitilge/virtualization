#!/usr/bin/env bash

qemu-img create -f qcow2 -o preallocation=metadata,compat=1.1,lazy_refcounts=on ./../images/Win10_1607_N_English_x64.img 64G
