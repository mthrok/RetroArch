import os
import time
import ctypes

rarch = ctypes.cdll.LoadLibrary('./wrapper.so')


class RAInterface(object):
    def __init__(self, rom, core):
        self.rom = os.path.abspath(rom)
        self.core = os.path.abspath(core)

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
        return rarch.step(self.ra)

    def run(self):
        return rarch.run(self.ra)

    def stop(self):
        rarch.stop(self.ra)
        rarch.RA_del(self.ra)

    def get_config(self):
        rarch.get_config(self.ra)


ra = RAInterface('super_mario_world.zip',
                 'snes9x2010_libretro.so')
ra.init()
# ra.run()
for i in range(500):
    ret = ra.step()
    # time.sleep(1/30)
    ra.get_config()
    if ret == -1:
        break
ra.stop()
