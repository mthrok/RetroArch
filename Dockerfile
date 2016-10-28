FROM ubuntu:14.04
RUN apt-get update
RUN apt-get install -y \
    git \
    build-essential \
    # Wrapper [NumPy and SciPy]
    swig \
    python \
    python-dev \
    python-pip \
    gfortran \
    libjpeg-dev \
    libblas-dev \
    liblapack-dev \
    # RetroArch
    freeglut3-dev \
    mesa-common-dev \
    libglu1-mesa-dev \
    libsdl2-dev \
    # GUI
    dbus \
    xvfb

RUN dbus-uuidgen > /var/lib/dbus/machine-id
RUN pip install Pillow numpy scipy

WORKDIR /opt
RUN git clone https://github.com/libretro/snes9x2010.git
WORKDIR /opt/snes9x2010
RUN make

WORKDIR /opt
RUN git clone -b swig/test https://github.com/mthrok/retroarch.git

WORKDIR /opt/retroarch
ADD ./setup.py ./
ADD ./retroarch.i ./
RUN ./configure && swig -python retroarch.i && python setup.py build_ext --inplace

RUN cp ../snes9x2010/snes9x2010_libretro.so ./snes9x2010_libretro.so

ADD puyopuyo.zip ./
ADD ./test.py ./
ADD ./test.sh ./

CMD ./test.sh
