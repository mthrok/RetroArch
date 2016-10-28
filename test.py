from __future__ import division
from __future__ import print_function

import sys

import retroarch as ra

core = 'snes9x2010_libretro.{}'.format(
    'dylib' if sys.platform == 'darwin' else 'so')

ra.start_rarch(core, 'puyopuyo.zip')
