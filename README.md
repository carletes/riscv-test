# RISC-V playground

## VisionFive 2

Documentation: https://doc-en.rvspace.org/Doc_Center/visionfive_2.html

### Booting with Firmware SD card

Using latest release from https://github.com/starfive-tech/VisionFive2/releases/tag/VF2_v2.11.5

Instructions on installing the firmware from https://forum.rvspace.org/t/visionfive-2-debian-image-released/994/75

Must select SD as boot medium with the board jumpers, because otherwise it cannot boot


### Boot with Debian SD card

Does not work on the VisionFive 2 out of the box --- need to update firmware first (see above)

Using Debian image 202303 on an SD card (starfive-jh7110-VF2-SD-wayland.img.bz2)

Card written with:

    $ sudo dd if=starfive-jh7110-VF2-SD-wayland.img of=/dev/sdb bs=8M status=progress

(Note that https://github.com/starfive-tech/VisionFive2 suggests `bs=4096`)

After first boot, the root partition must be
resized, so that it extends to the whole SD card:
https://doc-en.rvspace.org/VisionFive2/Quick_Start_Guide/VisionFive2_QSG/extend_partition.html

Update then to Debian unstable: https://www.ports.debian.org/archive

Halt the system, and save the contents of the SD card:

```
$ sudo virt-sparsify --tmp /root --verbose --format raw --convert qcow2 /dev/sdX visionfive-2-debian-ports-updated.qcow2
```

To reload:

```
$ sudo qemu-img convert -f qcow2 -O raw visionfive-2-debian-ports-updated.qcow2 /dev/sdX
```


### Install custom kernel

After the update, reboot and install Linux kernel with SECCOMP enabled:
https://rvspace.org/en/project/VisionFive2_Debian_Wiki_202303_Release

Once new kernel is in place, delete the old kernel DEBs, and save the SD
card contents:

```
$ sudo virt-sparsify --tmp /root --verbose --format raw --convert qcow2 /dev/sdX visionfive-2-custom-kernel.qcow2
```


### Booting with Debian eMMC

No luck yet.

Like above, but with an eMMC module instead.

Connecting the eMMC module to the board using J99 (the one to the right). It only fits on this one.


### Serial port setup

The dongle gets recognised as `/dev/ttyUSB0`, it seems, so

    $ sudo minicom -D /dev/ttyUSB0 -b 115200


### Network interfaces

```
root@starfive:~# ip l
1: lo: <LOOPBACK,UP,LOWER_UP> mtu 65536 qdisc noqueue state UNKNOWN mode DEFAULT group default qlen 1000
    link/loopback 00:00:00:00:00:00 brd 00:00:00:00:00:00
2: end0: <NO-CARRIER,BROADCAST,MULTICAST,UP> mtu 1500 qdisc mq state DOWN mode DEFAULT group default qlen 1000
    link/ether 6c:cf:39:00:32:f9 brd ff:ff:ff:ff:ff:ff
3: end1: <NO-CARRIER,BROADCAST,MULTICAST,UP> mtu 1500 qdisc mq state DOWN mode DEFAULT group default qlen 1000
    link/ether 6c:cf:39:00:32:fa brd ff:ff:ff:ff:ff:ff
4: sit0@NONE: <NOARP> mtu 1480 qdisc noop state DOWN mode DEFAULT group default qlen 1000
    link/sit 0.0.0.0 brd 0.0.0.0
root@starfive:~# 
```

