FROM ubuntu:18.04

RUN apt-get update && apt-get -y upgrade
RUN apt-get install -y --no-install-recommends \
	    python3 \
	    python3-setuptools \
	    python3-pip \
	    python3-dev

RUN apt-get install -y --no-install-recommends software-properties-common
RUN add-apt-repository universe
RUN add-apt-repository main
RUN apt-get update

# Build and install pyrealsense2
RUN apt-get install -y git libssl-dev libusb-1.0-0-dev pkg-config libgtk-3-dev cmake
RUN apt-get install -y libglfw3-dev libgl1-mesa-dev libglu1-mesa-dev
RUN git clone https://github.com/IntelRealSense/librealsense.git

WORKDIR /librealsense

# remove the `sudo`s in the script
RUN sed -i 's/sudo/ /g' ./scripts/setup_udev_rules.sh
RUN mkdir -p /etc/udev/rules.d/
RUN ./scripts/setup_udev_rules.sh

RUN mkdir build
WORKDIR /librealsense/build
RUN cmake ../ -DBUILD_PYTHON_BINDINGS:bool=true
RUN make uninstall && make clean && make -j4 && make install

# copy the built file over to path and call it done
RUN cp /usr/local/lib/python3.6/pyrealsense2/pyrealsense2.cpython-36m-x86_64-linux-gnu.so.2.50.0 /usr/local/lib/python3.6/dist-packages/pyrealsense2.cpython-36m-x86_64-linux-gnu.so


# Build and install cv2
ENV LC_ALL=C.UTF-8
ENV LANG=C.UTF-8
# Intel CPU Options
ARG AVX=ON
ARG AVX2=ON
ARG SSE41=ON
ARG SSE42=ON
ARG SSSE3=ON
ARG TBB=ON
# Include Intel IPP support
# Intel IPP software building blocks are highly optimized instruction sets (using Intel AVX, AVX2 and SSE).It offers a special subset of functions for image processing and computer vision called the IPP-ICV libraries. More information can be found here. Also here you can find some information about speedup.
ARG IPP=ON
# Include NVidia Cuda Runtime support
ARG CUDA=OFF
# Include NVidia Cuda Fast Fourier Transform (FFT) library support
ARG CUFFT=OFF
# Include NVidia Cuda Basic Linear Algebra Subprograms (BLAS) library support
ARG CUBLAS=OFF
# Include OpenCL Runtime support
ARG OPENCL=OFF
# Include OpenCL Shared Virtual Memory support" OFF ) experimental
ARG OPENCL_SVM=OFF
ARG OPENGL=ON
ARG GSTREAMER=ON
ARG FFMPEG=ON
ARG GTK=OFF
ARG QT=OFF
ARG NONFREE=OFF
# Include Intel Perceptual Computing SDK
ARG INTELPERC=OFF
ARG PREFIX=/usr/local
ARG VERSION=3.3.0
ARG PYTHON_BIN=/usr/bin/python3
ARG PYTHON_LIB=/usr/lib/x86_64-linux-gnu/libpython3.6m.so

WORKDIR /

RUN add-apt-repository "deb http://security.ubuntu.com/ubuntu xenial-security main"
RUN apt update

# LAPACKE is the C wrapper for the standard F90 LAPACK library. Honestly, its
# easier (and more efficient) to do things directly with LAPACK just as long as
# you store things column-major. LAPACKE ends up calling (in some fashion) the
# LAPACK routines anyways.
RUN apt-get update -q -y && apt-get install -y \
        build-essential \
        yasm \
        libswscale-dev \
        libeigen3-dev \
        libtbb2 \
        libtbb-dev \
        libjpeg-dev \
        libpng-dev \
        libtiff-dev \
        libjasper-dev \
        libavformat-dev \
        libpq-dev \
        libboost-all-dev \
        libgstreamer1.0-0 libgstreamer1.0-dev gstreamer1.0-libav gstreamer1.0-plugins-base \
        libblas-dev \
        liblapacke liblapacke-dev \
        libopenblas-dev libopenblas-base \
        libatlas-base-dev \
        liblapacke-dev liblapacke \
        && dpkg-query -Wf '${Installed-Size}\t${Package}\n' | sort -n \
        && apt-get clean \
        && rm -rf /var/lib/apt/lists

RUN pip3 install --upgrade pip \
 && pip3 install numpy \
 && pip3 install scipy \
 && rm -rf ~/.cache/pip

RUN curl --silent --location --location-trusted \
        --remote-name https://github.com/opencv/opencv/archive/$VERSION.tar.gz \
    && tar xf $VERSION.tar.gz -C / \
    && mkdir /opencv-$VERSION/cmake_binary \
    && cd /opencv-$VERSION/cmake_binary \
    && cmake \
        -DCMAKE_BUILD_TYPE=RELEASE \
        -DCMAKE_INSTALL_PREFIX=$PREFIX \
        -DOPENCV_ENABLE_NONFREE=$NONFREE \
        -DBUILD_opencv_java=OFF \
        -DWITH_CUDA=$CUDA \
        -DWITH_CUBLAS=$CUBLAS \
        -DWITH_CUFFT=$CUFFT \
        -DENABLE_AVX=$AVX \
        -DENABLE_AVX2=$AVX2 \
        -DENABLE_SSE41=$SSE41 \
        -DENABLE_SSE42=$SSE42 \
        -DENABLE_SSSE3=$SSSE3 \
        -DWITH_OPENGL=$OPENGL \
        -DWITH_GTK=$GTK \
        -DWITH_GSTREAMER=$GSTREAMER \
        -DWITH_OPENCL=$OPENCL \
        -DWITH_OPENCL_SVM=$OPENCL_SVM \
        -DWITH_TBB=$TBB \
        -DWITH_JPEG=ON \
        -DWITH_WEBP=ON \
        -DWITH_TIFF=ON \
        -DWITH_PNG=ON \
        -DWITH_QT=$QT \
        -DWITH_IPP=$IPP \
        -DWITH_EIGEN=ON \
        -DWITH_V4L=ON \
        -DWITH_INTELPERC=$INTELPERC \
        -DWITH_FFMPEG=$FFMPEG \
        -DENABLE_PRECOMPILED_HEADERS=ON \
        -DBUILD_opencv_python2=NO \
        -DBUILD_opencv_python3=ON \
        -DPYTHON3_EXECUTABLE=$PYTHON_BIN \
        -DPYTHON3_LIBRARIES=$PYTHON_LIB \
        -DPYTHON_LIBRARIES=$PYTHON_LIB \
        -DPYTHON3_INCLUDE_DIR=$($PYTHON_BIN -c "from distutils.sysconfig import get_python_inc; print(get_python_inc())") \
        -DPYTHON3_PACKAGES_PATH=$($PYTHON_BIN -c "from distutils.sysconfig import get_python_lib; print(get_python_lib())") .. \
        -DBUILD_DOCS=NO \
        -DBUILD_PERF_TESTS=OFF \
        -DBUILD_TESTS=OFF \
        -DBUILD_EXAMPLES=OFF \
        -DINSTALL_PYTHON_EXAMPLES=OFF \
        -DINSTALL_C_EXAMPLES=OFF \
    && make install \
    && rm -rf /$VERSION.tar.gz /opencv-$VERSION


# finally, install some common python packages
RUN pip3 install torch==1.10.2
RUN pip3 install pyserial==3.4
RUN pip3 install pytest==6.2.4

CMD bash
