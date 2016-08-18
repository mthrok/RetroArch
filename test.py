import os
import time
import ctypes
import threading

rarch = ctypes.cdll.LoadLibrary('./wrapper.so')


class RAInterface(object):
    def __init__(self, rom, core):
        self.rom = os.path.abspath(rom)
        self.core = os.path.abspath(core)

    def start(self):
        self.ra = rarch.RA_new()

        argc = ctypes.c_int(4)
        argv = (ctypes.c_char_p * 4)(
            'retroarch',
            self.rom,
            '-L', self.core
        )

        rarch.start(self.ra, argc, argv)

    def step(self):
        return rarch.step(self.ra)

ra = RAInterface('super_mario_world.zip',
                 'snes9x2010_libretro.so')
ra.start()
