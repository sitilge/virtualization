# Virtualization

This article is more like a follow-up guide to guide myself through the dangerous waters of virtualization. This guide is symbiosis of a magnificent [reddit post on GPU passthrough](https://www.reddit.com/r/pcmasterrace/comments/3lno0t/gpu_passthrough_revisited_an_updated_guide_on_how/), [a blog post](http://dominicm.com/gpu-passthrough-qemu-arch-linux/) and the [arch wiki](https://wiki.archlinux.org/index.php/PCI_passthrough_via_OVMF). The flow of the article will remain relatively close to the previously mentioned post and one should choose it over this one if well-grained details are required. I will also provide pitfalls I've encountered during the setup.
 
## Hardware

+ CPU: i5 6600K. You can easily check if your CPU supports IOMMU on this wiki [here](https://en.wikipedia.org/wiki/List_of_IOMMU-supporting_hardware). Don't be afraid if your CPU doesn't show up in the list - double check the manufacturer site. My CPU is not on the list yet [supports virtualization](https://ark.intel.com/products/88191/Intel-Core-i5-6600K-Processor-6M-Cache-up-to-3_90-GHz).

+ GPU: GTX 950. Your GPU has to support UEFI since OVMF will be used as the firmware. That should not be a problem for decent hardware.

+ Mobo: Asus Z170I pro gami0ng. I wanted to have a rather small build so this mini-itx mobo was a great choice and didn't cost me a fortune. The same list can be used to track down both your CPU and mobo, however, I was not able to find it there so I went through my UEFI settings instead.

+ Storage: Samsung 850 EVO 500GB. The virtual machine will reside in the `/home` partition.
 
 + Memory: 16GB DDR4. Since my host linux machine rarely uses more than 4GB, I safely pass 8GB to the virtual machine which is more than enough for mundane tasks and, yes, even light gaming.

+ Monitor: LG 23EA63. It's a basic monitor with DVI and HMDI ports. I'm feeding Nvidia output via DVI, leaving HDMI for iGPU.

+ Input: a set of simple Logitech keyboard + mouse. It is not a bad idea to have another pair with you since you'll be passing one pair to the virtual machine making it inaccessible from the host.
 
 ## Enable IOMMU
 
At the time I'm writing this, I'm running Arch, kernel version `4.9.8-1-ARCH`. The first thing you have to do is modify the loader entries under `/boot/loader/entries`. Turn on the iommu flag - edit the default entry by appending `intel_iommu=on`

````
options root=PARTUUID=95433c88-8e5b-4318-a3e0-508c5cbf22f1 rw intel_iommu=on
````
 Now `reboot` and check the output of `sudo dmesg | grep -e DMAR -e IOMMU` which should contain a line 
 
 ````
 `DMAR: IOMMU enabled`
 ````
 
Find information about the video card by running `lspci -nnk"`, locate the video card and the respective bus information

````
01:00.0 VGA compatible controller [0300]: NVIDIA Corporation GM206 [GeForce GTX 950] [10de:1402] (rev a1)
...
01:00.1 Audio device [0403]: NVIDIA Corporation Device [10de:0fba] (rev a1)
````

As you can see, my bus id is `01:00.0` and the ID's of the devices are `10de:1402` and `10de:0fba`. List the content of `ls /sys/bus/pci/devices/0000\:01\:00.0/iommu_group/devices/`. At the best-case scenario, you should only have one or two devices listed - your gpu bus and audio bus respectively. As it is in my case, the `PCI bridge` has the same IOMMU group (so I have three physical devices) because my CPU based PCIe slot does not support isolation properly. In reality, it does not matter that much but if you still want to have a clean group, I recommend switching to `linux-vfio` kernel described in the articles. Pitfall - make sure virtualization is supported and enabled in your firmware (UEFI). The option was hidden in a submenu in my case which resulted in a non-existing `iommu_group` directory.

 ## Isolate the GPU
 
 Newer kernel versions (>= Linux 4.1) include `vfio-pci` module by default. Enable the module by running `modprobe vfio-pci`. Next, edit the `/etc/modprobe.d/vfio.conf` and append the two IDs
 
 ````
 options vfio-pci ids=10de:1402,10de:0fba
 ````

Edit the `/etc/mkinitcpio.conf`, add the `vfio*` modules and ensure that `HOOKS` is included

````
MODULES="... vfio vfio_iommu_type1 vfio_pci vfio_virqfd ..."
HOOKS="... modconf ..."
````

Reboot and verify `vfio-pci` has been loaded `dmesg | grep -i vfio `.

## Setup KVM & QEMU & Windows

Run `sudo pacman -S qemu` to install `qemu`. The UEFI I am using is from the OVMF project. [Download](https://www.kraxel.org/repos/jenkins/edk2/) the latest build `edk2.git-ovmf-x64-XXXXXXX.noarch.rpm` and install the `rpmextract` package `sudo pacman -S rpmextract`, extract and copy the files `cd /tmp && rpmextract.sh edk2.git-ovmf-x64-XXXXXXX.noarch.rpm && sudo cp -R usr/share/* /usr/share/`.

The directories given in this project are there only to keep the structure clean. Download [virtio drivers](https://fedorapeople.org/groups/virt/virtio-win/direct-downloads/latest-virtio/virtio-win.iso) and [Windows ISO](https://www.microsoft.com/en-us/software-download/windows10ISO), then edit the filenames or the given `scripts/qemu-run.sh` script accordingly. Finally, run `scripts/qemu-create.sh` and `scripts/qemu-run.sh` to run the machine. Pitfall - check that you have plugged the correct cables in the respective ports and switched to the GPU source on your monitor. Pitfall - when browsing the virtio drivers, don't get confused and pick the ones given under `virtio iso -> virtscsi -> win10 -> amd64` because AMD64 architecture was adopted by Intel in its CPUs and is the common 64-bit extension of the x86 architecture used by both Intel and AMD CPUs. Pitfall - once the VM has been started, the mouse and keyboard passed won't be available on the host machine. It is wise to keep another combo with you if something goes wrong.