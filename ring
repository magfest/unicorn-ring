#!/usr/bin/env python3

from itertools import repeat, chain
import unicornhat as unicorn
from time import sleep, time
import sys
import os

RINGING_FILE = '/run/ringing'
RING_TIME = 60

with open(RINGING_FILE, 'a'):
    os.utime(RINGING_FILE, None)

unicorn.set_layout(unicorn.AUTO)
unicorn.rotation(0)
unicorn.brightness(1)
width,height=unicorn.get_shape()

cadence = "ffffff:100,000000:100," * 3 + "000000:300,"

if len(sys.argv) > 1:
    cadence = sys.argv[1]

def ncycles(iterable, n):
    "Returns the sequence elements n times"
    return chain.from_iterable(repeat(tuple(iterable), n))

def parse_cadence(desc):
    steps = [c for c in desc.split(',') if c]

    for step in desc.split(','):
        if not step:
            continue

        c, d = step.split(':')
        col = int(c, 16)
        dur = int(d)
        r, g, b = (col >> 16) & 255, (col >> 8) & 255, col & 255
        yield r, g, b, dur

def do_cadence(cadence, count=16):
    ring_start = time()
    for r, g, b, dur in ncycles(cadence, count):
        unicorn.set_all(r, g, b)
        unicorn.show()

        if time() > ring_start + RING_TIME or not os.path.isfile(RINGING_FILE):
            break

        sleep(dur / 1000)

do_cadence(parse_cadence(cadence))

os.remove(RINGING_FILE)
