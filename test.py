from __future__ import division
from __future__ import print_function

import sys

import retroarch as ra

core = 'snes9x2010_libretro.{}'.format(
    'dylib' if sys.platform == 'darwin' else 'so')

ra.rarch_init(['retroarch', 'puyopuyo.zip', '-L', core])
while True:
    ret = ra.rarch_step()
    if ret == -1:
        break
ra.rarch_exit();
