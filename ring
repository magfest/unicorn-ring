#!/usr/bin/env python3

import os
import sys

RINGING_FILE = '/run/ringing'

if os.path.isfile(RINGING_FILE):
    sys.exit(0)

with open(RINGING_FILE, 'a'):
    os.utime(RINGING_FILE, None)

from itertools import cycle
import unicornhat as unicorn
from time import sleep, time
import json

RING_TIME = 60

unicorn.set_layout(unicorn.AUTO)
unicorn.rotation(0)
unicorn.brightness(1)
width, height=unicorn.get_shape()

PATTERNS = {
    "full": [["X"] * width] * height,
    "phone": ["        ",
              "  XXXX  ",
              " XXXXXX ",
              "XX    XX",
              "XXX  XXX",
              "        ",
              " X    X ",
              "X X  X X"],
}

cadence = "ffffff:100,000000:100," * 3 + "000000:300,"
pattern = "full"
rotation = 0

try:
    with open("/var/last_config.json") as f:
        data = json.load(f)
        if 'cadence' in data:
            cadence = data['cadence']
except:
    raise
    pass

if len(sys.argv) > 1:
    cadence = sys.argv[1]

def parse_cadence(desc):
    global pattern
    steps = [c for c in desc.split(',') if c]

    while '=' in steps[0]:
        print("Removing", steps[0])
        step = steps.pop(0)
        opt, val = step.split('=')

        if opt == 'pattern':
            pattern = val
        elif opt == 'rotation':
            if val in (0, 90, 180, 270):
                unicorn.rotation(val)
        elif opt == "brightness":
            unicorn.brightness(min(1, max(0, float(val))))

    for step in steps:
        if not step:
            continue

        c, d = step.split(':')
        col = int(c, 16)
        dur = int(d)
        r, g, b = (col >> 16) & 255, (col >> 8) & 255, col & 255
        yield r, g, b, dur

def do_cadence(cadence):
    ring_start = time()
    for r, g, b, dur in cycle(cadence):
        if pattern == "full":
            unicorn.set_all(r, g, b)
        else:
            unicorn.set_pixels([[((r, g, b) if PATTERNS[pattern][y][x] != ' ' else (0, 0, 0)) for x in range(width)] for y in range(height)])

        unicorn.show()

        if time() > ring_start + RING_TIME or not os.path.isfile(RINGING_FILE):
            break

        sleep(dur / 1000)

try:
    do_cadence(parse_cadence(cadence))
finally:
    unicorn.set_all(0, 0, 0)

try:
    os.remove(RINGING_FILE)
except:
    pass
