from __future__ import division
from __future__ import print_function

import sys

import scipy.misc
import numpy as np

import retroarch as ra


core = 'snes9x2010_libretro.{}'.format(
    'dylib' if sys.platform == 'darwin' else 'so')

ra.rarch_init(['retroarch', 'puyopuyo.zip', '-L', core])
ra.rarch_get_memory_size()

w, h = ra.rarch_get_frame_size()
img = np.zeros((h, w, 3), dtype=np.float)
for i in range(1001):
    ret = ra.rarch_step()
    frame = ra.rarch_get_frame()[:h, :w]
    img[:, :, 0] = ((frame & 0b1111100000000000) >> 11) / (2 ** 5)
    img[:, :, 1] = ((frame & 0b0000011111100000) >> 5) / (2 ** 6)
    img[:, :, 2] = (frame & 0b0000000000011111) / (2 ** 5)
    # if i > 400 and i % 50 == 0:
    #     name = 'frame_{:03d}.png'.format(i)
    #     scipy.misc.toimage(img, cmin=0, cmax=1.0).save(name)
    #     print('saved', name)
    # ra.rarch_check_input()

    if ret == -1:
        break

ra.rarch_exit()
