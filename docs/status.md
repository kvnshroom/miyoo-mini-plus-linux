# Status (2026-10-11)

## Works in the QEMU model

- Linux 6.5 (linux-chenxing `mstar_v6_5_reorder` + `miyoo-mini-plus`) boots on
  both cores to a shell.
- Display: DRM/fbdev at 640×480 with the panel timing the vendor u-boot uses.
- Keys: all 18 via `gpio-keys-polled`; pads confirmed on a real unit.
- SD card: detected and partitions read.
- Battery and charger: AXP223 over I2C (capacity, voltage, status, current).
- Wi-Fi: AXP223 DLDO1/DLDO2 described as always-on, USB port 1 enabled,
  `rtl8xxxu` built in. The EHCI probe times out in the model because QEMU has
  no USB host controller for this SoC, so Wi-Fi is untested.
- The stock firmware still boots to its menu in the same model (regression
  check after every QEMU change).

## Missing or untested

- **Not booted on real hardware.** The vendor u-boot loads the kernel from SPI
  flash only; there is no SD boot path in the stock boot command, and the
  kernel (4.3 MB) does not fit the 2 MiB kernel partition.
- Display power: the kernel relies on u-boot having started the panel; it
  cannot switch the panel off and on (no suspend). The ST7703 init sequence is
  recorded in `docs/panel.md` for a future command-mode driver.
- Panel orientation on hardware (the vendor init sets MADCTL 0xc0, which
  probably flips the image in the panel).
- Backlight dimming, CPU frequency scaling and thermal, suspend.
- Power-off path: the Plus powers off through the AXP223, the kernel still
  uses the Mini's method.
- AXP223 interrupt line unknown, so no charger plug events.
- Audio: the driver loads, sound output untested.
- Wi-Fi firmware (`rtlwifi/rtl8188fufw.bin`) and userspace (`wpa_supplicant`)
  need a root filesystem; there is none yet beyond a test initramfs.

## Paths to real hardware considered

| Path | Flash writes | Needs | State |
|---|---|---|---|
| UART console: stop u-boot, load kernel from SD into RAM | none | opening the device, USB-serial adapter | not possible for the owner (no hardware) |
| Load a new kernel from the running vendor kernel (kexec) | none | a kexec module for the vendor 4.9.84 kernel | open, see below |
| Change the u-boot boot command to try the SD card first | 4 KiB environment sector | care and a rehearsal | open, see below |
| Replace the kernel in flash | kernel partition | — | not viable (size, removes the working system) |

## Open paths (not continued here)

Work on these two paths stopped at the points described. Both remain possible
ways to boot the mainline kernel on real hardware without opening the device,
for anyone who wants to continue them.

1. **kexec module for the vendor kernel.** Building modules the stock 4.9.84
   kernel accepts works: `tools/module-probe` loads and unloads cleanly in the
   model. Vermagic `4.9.84 SMP preempt mod_unload ARMv7 thumb2 p2v8`, no
   modversions, `struct module` of 0x1c0 bytes. To match it, configure the
   vendor source tree (github.com/shixmzh/ssd202d-kernel-4.9,
   `infinity2m_ssc011a_s01a_fastboot_defconfig`) with `CONFIG_BUG` and
   `CONFIG_JUMP_LABEL` off. The open part: a kexec module needs kernel
   internals that this kernel does not export to modules.
2. **SD-first u-boot boot command.** The u-boot environment is a 4 KiB sector
   at flash offset 0x5f000, inside the BOOT partition next to the bootloader.
   U-boot can be interrupted on the serial console and has `mmc`, `fatload`
   and `bootm`. The open part: rehearsing the changed environment in the
   emulator, including what u-boot does with a damaged environment, before
   anything is written on a device.

Nothing in this repo implements either path yet.

## Realistic next steps

- Offer the Mini Plus device tree, panel entry and config fragment to the
  linux-chenxing project, whose developers can test with a serial console.
- Build a Buildroot root filesystem with the Wi-Fi firmware and tools, ready
  for whenever a boot path exists.
- A QEMU model of the SoC's EHCI controller would let the USB stack be tested.
