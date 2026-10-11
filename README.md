# Miyoo Mini Plus – mainline Linux bring-up

Work towards running a current mainline Linux kernel on the **Miyoo Mini Plus**
handheld (SigmaStar SSD202D, 2× Cortex-A7, 128 MiB DDR3), as an alternative
base to the vendor 4.9 kernel used by the stock firmware and OnionOS.

Everything here was developed against the QEMU model of the device. The real
unit was only **read** (register dumps, pad levels, key and Wi-Fi tests); no
flash writes or firmware changes were made.

![Linux 6.5 framebuffer console in the QEMU model](docs/img/linux65-qemu-first-boot.png)

## Where the code lives

| Repo | Branch | What |
|---|---|---|
| [kvnshroom/linux](https://github.com/kvnshroom/linux/tree/miyoo-mini-plus) | `miyoo-mini-plus` | On top of linux-chenxing `mstar_v6_5_reorder` (6.5): Mini Plus device tree, panel, config fragment, Wi-Fi |
| [kvnshroom/qemu](https://github.com/kvnshroom/qemu/tree/miyoo-mini-plus) | `miyoo-mini-plus` | On top of fifteenhex `mstar-clean`: `miyoomini-plus` machine, AXP223 PMIC, I2C interrupts, RNG, SMP fix |
| this repo | `main` | Notes, measurements from the real device, helper scripts |

## Status

See [docs/status.md](docs/status.md) for what works, what is missing, and
where this work stopped.

Short version: the 6.5 kernel with the Plus device tree boots in QEMU on both
cores, with display, all keys, SD card, battery/charger readout and the Wi-Fi
power rails and USB port described. It has **not** been booted on real
hardware yet.

## Hardware findings

- [docs/panel.md](docs/panel.md) – the panel is a Sitronix ST7703 (2-lane MIPI
  DSI, 640×480); timing, init sequence, running config read from the device.
- [docs/axp223-regs-20261011.txt](docs/axp223-regs-20261011.txt) – AXP223 PMIC
  registers on a running unit (i2c-1 @ 0x34). USB-C power shows up on ACIN.
- [docs/keytest-20261011.txt](docs/keytest-20261011.txt) – every key pressed
  while logging pad levels. Same pads as the Mini except volume (TTL23/TTL24)
  and power (SAR0); all active low.
- [docs/wifi-power-20261011.txt](docs/wifi-power-20261011.txt) – toggling
  Wi-Fi switches AXP223 DLDO1 + DLDO2 (3.3 V); the RTL8188FU (0bda:f179)
  sits on SoC USB port 1.
- Vendor GPIO numbers map to pads through a table in the stock kernel image
  (24-byte entries: OEN, OUT, IN as address/mask pairs). Mainline GPIO offset
  = (address − 0x103c00) × 2; vendor 69/70 = PM_LED0/1, 71–74 = SAR GPIO0–3.

## Building

Kernel (Fedora: `dnf install gcc-arm-linux-gnu binutils-arm-linux-gnu dtc`):

```sh
git clone -b miyoo-mini-plus https://github.com/kvnshroom/linux.git
cd linux
make ARCH=arm CROSS_COMPILE=arm-linux-gnu- O=../build-linux mstar_defconfig miyoo_mini_plus.config
make ARCH=arm CROSS_COMPILE=arm-linux-gnu- O=../build-linux olddefconfig
make ARCH=arm CROSS_COMPILE=arm-linux-gnu- O=../build-linux -j$(nproc) zImage dtbs
```

QEMU:

```sh
git clone -b miyoo-mini-plus https://github.com/kvnshroom/qemu.git
cd qemu && mkdir build && cd build
../configure --target-list=arm-softmmu && ninja qemu-system-arm
```

Boot the kernel in the model (any initramfs with an armhf userspace works):

```sh
qemu-system-arm -M miyoomini-plus -kernel zImage \
  -dtb mstar-infinity2m-ssd202d-miyoo-mini-plus.dtb -initrd initramfs.cpio \
  -append "console=ttyS0,115200 rdinit=/init" -nographic
```

`scripts/run-headless.sh` boots the stock firmware from your own SPI dump in
the model and takes screenshots; `scripts/printk-dump.py` reads the vendor
kernel log out of a RAM dump (the vendor kernel never prints to the serial
port in the model).

## What is not in this repo

No firmware, flash or SD dumps, no OnionOS or Miyoo binaries, and no data from
the device beyond the register and pad readouts above. To use the scripts you
need a dump of your own device.

## Credits

Built on the work of the [linux-chenxing](https://github.com/linux-chenxing)
project (Daniel Palmer and contributors) for the mainline kernel and the QEMU
model of these SoCs.
