#!/usr/bin/env python
from __future__ import print_function
from __future__ import absolute_import

from distutils.core import setup, Extension

import make_parser


def main():
    print('Parsing Make command')
    _option = make_parser.parse_make_option()

    print('Building extension')
    module1 = Extension(
        '_retroarch',
        sources=['retroarch_wrap.c'] + _option['source_files'],
        include_dirs=_option['include_dirs'],
        extra_compile_args=_option['compile_flags'],
        extra_link_args=_option['ld_flags'],
    )

    setup(
        name='RetroArch',
        version='0.1.0',
        description='Python wrapper for RetroArch',
        ext_modules=[module1],
        py_modules=['RetroArch'],
    )


if __name__ == '__main__':
    main()
