#!/usr/bin/env python3
"""Extract the Linux 4.9 printk ring buffer from a raw RAM dump (pmemsave).

The vendor kernel's console never reaches the emulated UART, so this is the
way to read its log. Finds the record whose text starts with "Linux version"
and walks the variable-length printk records from there.
"""
import sys

data = open(sys.argv[1], "rb").read()
marker = b"Linux version 4.9"
pos = -1
for i in range(data.count(marker)):
    pos = data.find(marker, pos + 1)
    start = pos - 16
    ln = int.from_bytes(data[start + 8:start + 10], "little")
    if 16 < ln < 2048:
        break
else:
    sys.exit("no printk buffer found")

p = start
while p + 16 < len(data):
    ln = int.from_bytes(data[p + 8:p + 10], "little")
    tl = int.from_bytes(data[p + 10:p + 12], "little")
    if ln < 16 or ln > 2048 or tl > ln:
        break
    ts = int.from_bytes(data[p:p + 8], "little") / 1e9
    print("[%10.3f] %s" % (ts, data[p + 16:p + 16 + tl].decode("latin1")))
    p += ln
