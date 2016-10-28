import os
import sys
from subprocess import check_output


def parse_compile_option(command):
    compile_flags = []
    include_dirs = []
    for arg in command.split(' ')[1:]:
        if not arg or arg in ['-c', '-o']:
            continue

        ext = os.path.splitext(arg)[1]
        if ext in ['.o']:
            continue
        elif ext in ['.c', '.m', '.cpp']:
            source_file = arg
        elif arg.startswith('-I'):
            include_dirs.append(arg[2:])
        elif arg.startswith('-std='):
            # In MacOS compilation, -std=gnu99 is defined for C file and
            # -std=c++99 is defined for cpp file, but neither works with
            # objective C file, so we ignore both
            if sys.platform == 'darwin':
                continue
            compile_flags.append(arg)
        else:
            arg = arg.replace('\'', '')
            compile_flags.append(arg)
    return source_file, include_dirs, compile_flags


def parse_link_option(command):
    ld_flags = []
    for arg in command.split(' '):
        if arg.startswith('-l'):
            ld_flags.append(arg)
    return ld_flags


def parse_make_option():
    check_output('./configure')
    check_output(['make', 'clean'])
    commands = [
        line for line in check_output(['make', '-n']).split('\n')
        if line and not line.startswith('mkdir') and not line.startswith('echo')
    ]

    compiles, ld = commands[:-1], commands[-1]
    source_files, include_dirs, compile_flags = [], set(), set()
    for command in compiles:
        s_file, incl_dirs, c_flags = parse_compile_option(command)
        source_files.append(s_file)
        include_dirs.update(incl_dirs)
        compile_flags.update(c_flags)
    ld_flags = parse_link_option(ld)

    if sys.platform == 'darwin':
        os.environ['MACOSX_DEPLOYMENT_TARGET'] = '10.6'
        compile_flags.add('-mmacosx-version-min=10.6')
        ld_flags.extend([
            '-lobjc',
            '-framework', 'CoreFoundation',
            '-framework', 'CoreLocation',
            '-framework', 'CoreGraphics',
            '-framework', 'AppKit',
            '-framework', 'OpenAL',
            '-framework', 'OpenGL',
        ])

    return {
        'source_files': source_files,
        'include_dirs': list(include_dirs),
        'compile_flags': list(compile_flags),
        'ld_flags': ld_flags
    }
