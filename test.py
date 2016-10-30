from __future__ import division
from __future__ import print_function

import sys

import retroarch as ra

core = 'snes9x2010_libretro.{}'.format(
    'dylib' if sys.platform == 'darwin' else 'so')

ra.init_rarch(core, 'puyopuyo.zip')
while True:
    ret = ra.step_rarch()
    if ret == -1:
        break
ra.exit_rarch();
