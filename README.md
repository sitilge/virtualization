# Virtualization

This article is more like a follow-up to guide myself through the dangerous waters of virtualization. This readme is symbiosis of the magnificent [reddit post on GPU passthrough](https://www.reddit.com/r/pcmasterrace/comments/3lno0t/gpu_passthrough_revisited_an_updated_guide_on_how/), this [blog post](http://dominicm.com/gpu-passthrough-qemu-arch-linux/) and the [arch wiki](https://wiki.archlinux.org/index.php/PCI_passthrough_via_OVMF). The flow of the article will remain relatively close to the other posts and one should choose them over this one if well-grained details are required. I will also provide pitfalls I've encountered during the setup.
 
## Host setup

+ OS: arch linux running `4.9.8-1-ARCH` kernel. `systemd-boot` is used as the bootloader. The physical disk has three partitions `/`, `/boot`, `/home`.

+ CPU: i5 6600K. You can easily check if your CPU supports IOMMU on this wiki [here](https://en.wikipedia.org/wiki/List_of_IOMMU-supporting_hardware). Don't be afraid if your CPU does not show up in the list - double check the manufacturer site. My CPU is not on the list yet [supports virtualization](https://ark.intel.com/products/88191/Intel-Core-i5-6600K-Processor-6M-Cache-up-to-3_90-GHz).

+ GPU: Nvidia GTX 950. Your GPU has to support UEFI since OVMF will be used as the firmware. That should not be a problem for decent hardware.

+ Mobo: Asus Z170I. I wanted to have a rather small build so this mini-itx mobo was a great choice and did not cost me a fortune. The same list can be used to track down both your CPU and mobo, however, I was not able to find it there so I went through my UEFI settings instead.

+ Storage: Samsung 850 EVO 500GB. The virtual machine will reside in the `/home` partition.
 
+ Memory: 16GB DDR4. Since my host linux machine rarely uses more than 4GB, I safely pass 8GB to the virtual machine which is more than enough for mundane tasks, light CAD, etc.

+ Monitor: LG 23EA63. It's a basic monitor with DVI and HMDI ports. I'm feeding Nvidia output via DVI, leaving HDMI for iGPU.

+ Input: a set of simple Logitech keyboard + mouse. It is not a bad idea to have another pair with you since you'll be passing one pair to the virtual machine making it inaccessible from the host.

**Pitfall #0** - you might want to `pacman -Syu` beforehand. This happened to me once, updating the kernel was the solution.

## Enable IOMMU
 
The first thing you have to do is modify the loader entries under `/boot/loader/entries`. Turn on the iommu flag - edit the default entry by appending `intel_iommu=on`

````
options root=PARTUUID=95433c88-8e5b-4318-a3e0-508c5cbf22f1 rw intel_iommu=on
````
 Now `reboot` and check the output of `sudo dmesg | grep -e DMAR -e IOMMU` which should contain a line 
 
 ````
 `DMAR: IOMMU enabled`
 ````
 
Find information about the video card by running `lspci -nnk`, locate the video card and the respective bus information

````
01:00.0 VGA compatible controller [0300]: NVIDIA Corporation GM206 [GeForce GTX 950] [10de:1402] (rev a1)
...
01:00.1 Audio device [0403]: NVIDIA Corporation Device [10de:0fba] (rev a1)
````

As you can see, my bus id is `01:00.0` and the ID's of the devices are `10de:1402` and `10de:0fba`. Check the content of `ls /sys/bus/pci/devices/0000\:01\:00.0/iommu_group/devices/`. At the best-case scenario, you should only have one or two devices listed - your GPU bus and audio bus respectively. As it is in my case, the `PCI bridge` has the same IOMMU group (so I have three physical devices in one IOMMU group). This happens because my CPU based PCIe slot does not support isolation properly. In reality, it does not matter that much but if you still want to have a clean group, I recommend switching to `linux-vfio` kernel described in the articles.

**Pitfall #1** - make sure virtualization is supported and enabled in your firmware (UEFI). The option was hidden in a submenu in my case which resulted in a non-existing `iommu_group` directory.

## Isolate the GPU
 
 Newer kernel versions (>= Linux 4.1) include `vfio-pci` module by default. Enable the module by running `modprobe vfio-pci`. Next, edit the `/etc/modprobe.d/vfio.conf` and append the two IDs
 
 ````
options vfio-pci ids=10de:1402,10de:0fba
 ````

Edit the `/etc/mkinitcpio.conf`, add the `vfio` modules and ensure that `HOOKS` is included

````
MODULES="... vfio vfio_iommu_type1 vfio_pci vfio_virqfd ..."
HOOKS="... modconf ..."
````

Regenerate `mkinitcpio -p linux`, then reboot and verify that `vfio-pci` has been loaded `dmesg | grep -i vfio `.

## Guest setup

Run `sudo pacman -S qemu` to install `qemu`. The UEFI I am using is from the OVMF project. [Download](https://www.kraxel.org/repos/jenkins/edk2/) the latest build `edk2.git-ovmf-x64-XXXXXXX.noarch.rpm` and install the `rpmextract` package `sudo pacman -S rpmextract`. Now extract and copy the files

 ````
ovmf=edk2.git-ovmf-x64-XXXXXXX.noarch.rpm && \
mv $ovmf /tmp && \
(cd /tmp && rpmextract.sh $ovmf && \
sudo cp -R usr/share/* /usr/share/)
 ````

Download
 
 + [virtio drivers](https://fedorapeople.org/groups/virt/virtio-win/direct-downloads/latest-virtio/virtio-win.iso) - you can safely skip this step and edit the `qemu-run.sh` if you do not want `qcow` containers.
 
 + [Windows ISO](https://www.microsoft.com/en-us/software-download/windows10ISO) - I'm using Windows 10 N version (no media software).
 
The directories given in this project are there only to keep the structure clean. I suggest putting the files under the directories given to keep the structure clean. Also, remember to rename your files and/or update the `scripts` with the correct filenames of the downloaded drivers and ISO.

Change to `cd scripts` directory. The `qemu-create.sh`
 
 ````
 qemu-img create -f qcow2 -o preallocation=metadata,compat=1.1,lazy_refcounts=on ./../images/Win10_1607_N_English_x64.img 64G
 ````
 
 Basically, I create a `qcow` container with storage size of 64GB. The other arguments are for optimization (read the first post for more info).
 
 The `qemu-run.sh` script content for running the virtual machine is as follows
 
 ````
cp /usr/share/edk2.git/ovmf-x64/OVMF_VARS-pure-efi.fd /tmp/OVMF_VARS-pure-efi.fd

QEMU_PA_SAMPLES=128 QEMU_AUDIO_DRV=pa

qemu-system-x86_64 \
  -enable-kvm \
  -m 8196 \
  -smp cores=4,threads=1 \
  -cpu host,kvm=off \
  -vga none \
  -soundhw hda \
  -usb -usbdevice host:046d:c077 -usbdevice host:046d:c31c \
  -device vfio-pci,host=01:00.0,multifunction=on \
  -device vfio-pci,host=01:00.1 \
  -drive if=pflash,format=raw,readonly,file=/usr/share/edk2.git/ovmf-x64/OVMF_CODE-pure-efi.fd \
  -drive if=pflash,format=raw,file=/tmp/OVMF_VARS-pure-efi.fd \
  -device virtio-scsi-pci,id=scsi \
  -drive file=./../windows/Win10_1607_N_English_x64.iso,id=isocd,format=raw,if=none -device scsi-cd,drive=isocd \
  -drive file=./../images/Win10_1607_N_English_x64.img,id=disk,format=qcow2,if=none,cache=writeback -device scsi-hd,drive=disk \
  -drive file=./../virtio/virtio-win-0.1.130.iso,id=virtiocd,if=none,format=raw -device ide-cd,bus=ide.1,drive=virtiocd
 ````
 
In general, I'm running a 64 bit operating system which has the same CPU parameters as the host machine, with 8GiB of memory. Run `lspci -nnk` and grep the IDs of your mouse and keyboard (in my case `046d:c077` and `046d:c31c`). Preferably, get another combo- when the guest VM is started, the host won't be able to use the mouse & keyboard passed to the guest. Edit the `device vfio-pci ...` lines and set the bus of your video card. Here, the `01:00.0` is the GPU and `01:00.0` is the audio device.

**Pitfall #2** - check that you have plugged the correct cables in the respective ports and switched to the GPU source on your monitor (DVI in my case).

**Pitfall #3** - when browsing for the virtio drivers, don't get confused and pick the ones given under `virtio iso -> virtscsi -> win10 -> amd64` because AMD64 architecture was adopted by Intel in its CPUs and is the common 64 bit extension of the x86 architecture used by both Intel and AMD CPUs.

**Pitfall #4** - once the VM has been started, the mouse and keyboard passed won't be available on the host machine. It is wise to keep another combo with you if something goes wrong.

**Pitfall #5** - it took more than 10 minutes for the guest machine to recognize the Nvidia. The issue was solved when I updated the Windows guest machine and downloaded the Nvidia drivers.
