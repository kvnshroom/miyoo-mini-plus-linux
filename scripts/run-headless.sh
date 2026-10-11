#!/bin/bash
# Boot a copy of a SPI NOR dump in the miyoomini QEMU model without a window.
# Usage: [MACHINE=miyoomini-plus] [CMDS=file] run-headless.sh <run-name> [seconds] [sd-image]
# CMDS: shell commands typed on the serial console 90 s after power-on,
# CMDS_DELAY seconds apart (default 3).
# Writes serial.log, shot-<t>.png every 30 s, mem.bin and dmesg.txt to runs/<run-name>/.
set -euo pipefail
P=$(cd "$(dirname "$0")/.." && pwd)
NAME=$1
SECS=${2:-180}
SD=${3:-}
R=$P/runs/$NAME
mkdir -p "$R"
cd "$R"
rm -f mon.sock
cp "$P/backup/spi-20261011/spi_full.bin" nor.bin
SDARGS=()
[ -n "$SD" ] && SDARGS=(-drive "if=sd,format=raw,file=$SD,snapshot=on")
"$P/src/qemu/build/qemu-system-arm" -M "${MACHINE:-miyoomini-plus}" -drive if=mtd,format=raw,file=nor.bin \
  "${SDARGS[@]}" -display none -audio none -chardev socket,id=s0,path="$R/ser.sock",server=on,wait=off,logfile="$R/serial.log" -serial chardev:s0 \
  -monitor unix:"$R/mon.sock",server,nowait -d unimp,guest_errors -D qemu.log &
QPID=$!
mon() { (
  echo "$1"
  sleep "${2:-1}"
) | socat - UNIX-CONNECT:"$R/mon.sock" >/dev/null; }
sleep 2
if [ -n "${CMDS:-}" ]; then
  (sleep 88; while read -r c; do printf '%s\n' "$c"; sleep "${CMDS_DELAY:-3}"; done < "$CMDS"; sleep 2) |
    socat - UNIX-CONNECT:"$R/ser.sock" > /dev/null &
fi
for ((t = 30; t <= SECS; t += 30)); do
  sleep 30
  mon "screendump \"$R/shot-$t.ppm\""
  magick "shot-$t.ppm" "shot-$t.png" 2>/dev/null && rm -f "shot-$t.ppm"
done
mon "pmemsave 0x20000000 0x8000000 \"$R/mem.bin\"" 15
mon quit
wait $QPID || true
python3 -I "$P/scripts/printk-dump.py" mem.bin >dmesg.txt || true
echo "run $NAME done: $(wc -l <dmesg.txt) kernel log lines"
