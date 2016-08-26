from __future__ import division
from __future__ import print_function

import os
import time
import ctypes

import numpy as np
import scipy.misc


rarch = ctypes.cdll.LoadLibrary('./wrapper.so')


class RAInterface(object):
    def __init__(self, rom, core):
        self.rom = os.path.abspath(rom)
        self.core = os.path.abspath(core)

        self.ra = None

        self.frame = None
        self.frame_pointer = ctypes.c_void_p()
        self.frame_width = ctypes.c_uint()
        self.frame_height = ctypes.c_uint()
        self.frame_pitch = ctypes.c_size_t()

        self.frame_pointer_ = ctypes.byref(self.frame_pointer)
        self.frame_width_ = ctypes.byref(self.frame_width)
        self.frame_height_ = ctypes.byref(self.frame_height)
        self.frame_pitch_ = ctypes.byref(self.frame_pitch)

    def init(self):
        self.ra = rarch.RA_new()
        argc = ctypes.c_int(4)
        argv = (ctypes.c_char_p * 4)(
            'retroarch',
            self.rom,
            '-L', self.core
        )
        rarch.init(self.ra, argc, argv)

    def step(self):
        # TODO: Clean up return values
        ret = rarch.step(self.ra)
        self.get_frame()
        return ret

    def run(self):
        return rarch.run(self.ra)

    def stop(self):
        rarch.stop(self.ra)
        rarch.RA_del(self.ra)

    def get_config(self):
        rarch.get_config(self.ra)

    def get_screen_info(self):
        rarch.get_screen_info(self.ra)

    def get_frame_count(self):
        return rarch.get_frame_count(self.ra)

    def get_frame(self):
        rarch.get_frame(
            self.ra, self.frame_pointer_,
            self.frame_width_, self.frame_height_,
            self.frame_pitch_
        )

        pixel_format = rarch.get_pixel_format(self.ra)
        if pixel_format == 2:
            # RETRO_PIXEL_FORMAT_RGB565
            data = ctypes.cast(self.frame_pointer,
                               ctypes.POINTER(ctypes.c_ushort))
            height = self.frame_height.value
            width = self.frame_width.value
            pitch = self.frame_pitch.value
            shape = (height, pitch // 2)
            arr = np.ctypeslib.as_array(data, shape=shape)
            arr = arr[:, :width]
            if self.frame is None:
                shape = (3, height, width)
                self.frame = np.zeros(shape, dtype=np.uint8)
            # Red
            self.frame[0, :, :] = ((arr & 0b1111100000000000) >> 11) * 8
            # Green
            self.frame[1, :, :] = ((arr & 0b0000011111100000) >> 5) * 4
            # Blue
            self.frame[2, :, :] = (arr & 0b0000000000011111) * 8
            return self.frame
        else:
            # RETRO_PIXEL_FORMAT_0RGB1555
            # RETRO_PIXEL_FORMAT_XRGB8888
            # RETRO_PIXEL_FORMAT_UNKNOWN
            raise NotImplementedError()

ra = RAInterface('super_mario_world.zip',
                 'snes9x2010_libretro.so')
ra.init()
# ra.run()
for i in range(500):
    ret = ra.step()
    # time.sleep(1/30)
    frame_count = ra.get_frame_count()
    if frame_count % 400 == 399:
        ra.get_config()
        ra.get_screen_info()
        name = 'frame_{}.png'.format(frame_count)
        scipy.misc.toimage(ra.frame).save(name)
    if ret == -1:
        break
ra.stop()
