set -e

rm -rf obj-unix/wrapper.*
make VERBOSE=1 -f MakeWrapper

# readelf -Ws 'wrapper.so' | grep RA
python test.py
