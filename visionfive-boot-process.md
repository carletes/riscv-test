# The boot process of a VisionFive 2 board

## Hardware involved in the boot process

### The processor 

According to the [VisionFive 2 datasheet][] the VisionFive 2 has a StarFive
JH7110 processor, with:
* a U74 quad-core 64-bit SoC with RV64GC ISA, 2 MB L2 cache, running at up to
  1.5 GHz.
* a S7 monitor core with RV64GC ISA, running at up to 1.5 GHz

The acronym "RV64GC" means the JH7110 supports:
* 64-bit integer register size, and size of user address space
* General purpose instruction set
* 16-bit compresed instructions.

According to the [SiFive U74-MC core complex manual][], the "B" extension
(supporting bit manipulation instructions) is optional and may also be
present.


### Memory

The board supports 2, 4, or 8 GB LPDDR4 SRAM, operating at up to 2,800 Mbps.

According to the [SiFive U74-MC core complex manual][], the memory map is as
follows:

| Base        | Top         | PMA    | Description               |
|-------------|-------------|--------|---------------------------|
| 0x0000_0000 | 0x0000_0FFF |        | Debug                     |
| 0x0000_1000 | 0x0000_2FFF |        | Reserved                  |
| 0x0000_3000 | 0x0000_3FFF | RWX A  | Error Device              |
| 0x0000_4000 | 0x00FF_FFFF |        | Reserved                  |
| 0x0100_0000 | 0x0100_1FFF | RWX A  | S7 Hart 0 DTIM (8 KiB)    |
| 0x0100_2000 | 0x016F_FFFF |        | Reserved                  |
| 0x0170_0000 | 0x0170_0FFF | RW A   | S7 Hart 0 Bus-Error Unit  |
| 0x0170_1000 | 0x0170_1FFF | RW A   | U7 Hart 1 Bus-Error Unit  |
| 0x0170_2000 | 0x0170_2FFF | RW A   | U7 Hart 2 Bus-Error Unit  |
| 0x0170_3000 | 0x0170_3FFF | RW A   | U7 Hart 3 Bus-Error Unit  |
| 0x0170_4000 | 0x0170_4FFF | RW A   | U7 Hart 4 Bus-Error Unit  |
| 0x0170_5000 | 0x017F_FFFF |        | Reserved                  |
| 0x0180_0000 | 0x0180_3FFF | RWX A  | S7 Hart 0 ITIM            |
| 0x0180_4000 | 0x01FF_FFFF |        | Reserved                  |
| 0x0200_0000 | 0x0200_FFFF | RW A   | CLINT                     |
| 0x0201_0000 | 0x0201_3FFF | RW A   | L2 Cache Controller       |
| 0x0201_4000 | 0x0202_FFFF |        | Reserved                  |
| 0x0203_0000 | 0x0203_1FFF | RW A   | U7 Hart 1 L2 Prefetcher   |
| 0x0203_2000 | 0x0203_3FFF | RW A   | U7 Hart 2 L2 Prefetcher   |
| 0x0203_4000 | 0x0203_5FFF | RW A   | U7 Hart 3 L2 Prefetcher   |
| 0x0203_6000 | 0x0203_7FFF | RW A   | U7 Hart 4 L2 Prefetcher   |
| 0x0203_8000 | 0x07FF_FFFF |        | Reserved                  |
| 0x0800_0000 | 0x081F_FFFF | RWX A  | L2 LIM                    |
| 0x0820_0000 | 0x09FF_FFFF |        | Reserved                  |
| 0x0A00_0000 | 0x0A1F_FFFF | RWXI A | L2 Zero Device            |
| 0x0A20_0000 | 0x0BFF_FFFF |        | Reserved                  |
| 0x0C00_0000 | 0x0FFF_FFFF | RW A   | PLIC                      |
| 0x1000_0000 | 0x1FFF_FFFF |        | Reserved                  |
| 0x2000_0000 | 0x3FFF_FFFF | RWXI A | Peripheral Port (512 MiB) |
| 0x4000_0000 | 0x5FFF_FFFF | RWXI   | System Port (512 MiB)     |
| 0x6000_0000 | 0x7FFF_FFFF |        | Reserved                  |
| 0x8000_0000 | 0x9FFF_FFFF | RWXIDA | Memory Port (512 MiB)     |
| 0xA000_0000 | 0xFFFF_FFFF |        | Reserved                  |

"PMA" stands for "physical memory attributes", and the values used in the
table above are:
* "R" for read
* "W" for write
* "X" for execute
* "I" for instruction-cacheable
* "D" for data-cacheable
* "A" for atomics


### Storage

The board has the following storage devices:
* A TF card slot for SD cards
* A 1-bit QSPI NOR flash memory chip. The [JH7110 boot user guide][] seems to
  imply it has at least 16 MiB of capacity.
* An eMMC slot

The board has also a 32 KB boot ROM chip.


## RISC-V execution modes

RISC-V processors may run in three different execution modes:

* M-mode (machine mode): The platform runtime firmware. This is the highest
  privileged mode (level 3). It has access to all control and status registers
  and instructions.
* S-mode (supervisor mode): The operating system kernel. Its privilege level is
  1 (lower than M-mode). It has access to some control and status registers and
  instructions.
* U-mode (user mode): Userland applications. Its privilege level is 0 (the
  lowest of all).


## The boot process

The boot process is described in the [JH7110 boot user guide][].

There are five stages in the boot process:

```
ROM -> LOADER -> [RUNTIME] -> BOOTLOADER -> OS
```

In the `ROM` stage, the system runs the Zero-Stage-Boot-Loader (ZSBL) code
from the on-chip ROM, which seems to be accessible from the memory address
0x2A00_0000 (in U74 memory map terms, that's located in the "Peripheral
port" area.

This code basically loads the Secondary Program Loader (SPL) to SRAM at the
address 0x800_0000. The source of the SPL is selected by the pins GPIO0
and GPIO1, which are mapped to the memory address 0x1702_002C.

When the GPIO0 and GPIO1 pins select the QSPI flash memory as the boot
source, its content is expected to be the following:

| Offset      | Length     | Description                         |
|-------------|------------|-------------------------------------|
| 0x0         | 0x8_0000   | SPL                                 |
| 0x000F_0000 | 0x1_0000   | U-Boot environment variables        |
| 0x0010_0000 | 0x40_0000  | `fw_payload.img` (OpenSBI + U-Boot) |
| 0x0060_0000 | 0x100_0000 | Reseved                             |

The contents of the SD card or the eMMC module are expected to be the following:

| Offset      | Length      | Description                         | Comment             |
|-------------|-------------|-------------------------------------|---------------------|
| 0x0000_0000 | 0x200       | GPT PMBR                            | 0x4: Backup address |
| 0x0000_0200 | 0x200       | GPT Header                          |                     |
| 0x0000_0400 | 0x1F_FC00   | Reserved 	                          |                     |
| 0x0020_0000 | 0x20_0000   | SPL                                 | Partition 1         |
| 0x0040_0000 | 0x40_0000   | `fw_payload.img` (OpenSBI + U-Boot) | Partition 2         |
| 0x0080_0000 | 0x1240_0000 | Initramfs + `UEnv.txt`              | Partition 3         |
| 0x12C0_0000 | End of disk | System rootfs                       | Partition 4         |

In the `LOADER` stage, the SPL code has been loaded into memory. This SPL
code is a boot program based on U-Boot. Its mission is to initialise the
DDR (the rest of the memory ???), and then to load the `fw_payload.img`
firmware code to address 0x4000_0000 (which lies in the "System port"
memory area in terms of the U74 memory map).

At this address 0x4000_0000, as part of the `fw_payload.img`, lies
OpenSBI. Its purpose is:
* To switch the CPU from M-mode to S-mode,
* To jump to address 0x4020_0000 to continue with the boot process, and
* To stay in memory, to provide system call support to the Linux kernel.

The `RUNTIME` stage is not really a stage (hence the `[RUNTIME]`
nomenclature), since it does not end: The OpenSBI code stays in memory and
gets called when needed by the Linux kernel.

At the `BOOTLOADER` stage finally, the system is now running U-Boot in S-mode
(starting at address 0x4020_0000). Its purpose is to load the (Linux) kernel.



[JH7110 boot user guide]: https://doc-en.rvspace.org/VisionFive2/Boot_UG/
[VisionFive 2 datasheet]: https://doc-en.rvspace.org/VisionFive2/Datasheet/
[SiFive U74-MC core complex manual]: https://starfivetech.com/uploads/u74mc_core_complex_manual_21G1.pdf
