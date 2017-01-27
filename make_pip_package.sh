#!/usr/bin/env bash

# Set up path as temporary working directory
DEPS_PATH=$PWD/deps
rm -rf $PWD/deps
mkdir $DEPS_PATH

# Dependencies can be updated here. Be sure to verify the download link before
# changing. The dependencies are:
ZLIB_VERSION=1.2.6
OPENBLAS_VERSION=0.2.19
JPEG_VERSION=8.4.0
PNG_VERSION=1.5.10
TIFF_VERSION=3.8.2
OPENCV_VERSION=2.4.13

# Setup path to dependencies
export PKG_CONFIG_PATH=$DEPS_PATH/lib/pkgconfig:$DEPS_PATH/lib64/pkgconfig:$PKG_CONFIG_PATH
export CPATH=$DEPS_PATH/include:$CPATH

# Position Independent code must be turned on for statically linking .a
export CC="gcc -fPIC"
export CXX="g++ -fPIC"

# Download and build zlib
curl -L https://github.com/LuaDist/zlib/archive/$ZLIB_VERSION.zip -o $DEPS_PATH/zlib.zip
unzip $DEPS_PATH/zlib.zip -d $DEPS_PATH
mkdir $DEPS_PATH/zlib-$ZLIB_VERSION/build
cd $DEPS_PATH/zlib-$ZLIB_VERSION/build
cmake -D CMAKE_BUILD_TYPE=RELEASE \
      -D CMAKE_INSTALL_PREFIX=$DEPS_PATH \
      -D BUILD_SHARED_LIBS=OFF .. || exit -1
make -j$(nproc) || exit -1
make install
cd -

# download and build openblas
curl -L https://github.com/xianyi/OpenBLAS/archive/v$OPENBLAS_VERSION.zip -o $DEPS_PATH/openblas.zip
unzip $DEPS_PATH/openblas.zip -d $DEPS_PATH
cd $DEPS_PATH/OpenBLAS-$OPENBLAS_VERSION
make FC=gfortran -j $(($(nproc) + 1)) || exit -1
make PREFIX=$DEPS_PATH install
cd -
ln -s $DEPS_PATH/lib/libopenblas_haswellp-r0.2.19.a $DEPS_PATH/lib/libcblas.a

# download and build libjpeg
curl -L https://github.com/LuaDist/libjpeg/archive/$JPEG_VERSION.zip -o $DEPS_PATH/libjpeg.zip
unzip $DEPS_PATH/libjpeg.zip -d $DEPS_PATH
cd $DEPS_PATH/libjpeg-$JPEG_VERSION
./configure --disable-shared --prefix=$DEPS_PATH || exit -1
make -j$(nproc) || exit -1
make test || exit -1
make install
cd -

# download and build libpng
curl -L https://github.com/LuaDist/libpng/archive/$PNG_VERSION.zip -o $DEPS_PATH/libpng.zip
unzip $DEPS_PATH/libpng.zip -d $DEPS_PATH
mkdir $DEPS_PATH/libpng-$PNG_VERSION/build
cd $DEPS_PATH/libpng-$PNG_VERSION/build
cmake -D CMAKE_BUILD_TYPE=RELEASE \
      -D CMAKE_INSTALL_PREFIX=$DEPS_PATH \
      -D PNG_CONFIGURE_LIBPNG=-fPIC \
      -D BUILD_SHARED_LIBS=OFF .. || exit -1
make -j$(nproc) || exit -1
make install
cd -

# download and build libtiff
curl -L https://github.com/LuaDist/libtiff/archive/$TIFF_VERSION.zip -o $DEPS_PATH/libtiff.zip
unzip $DEPS_PATH/libtiff.zip -d $DEPS_PATH
cd $DEPS_PATH/libtiff-$TIFF_VERSION
./configure --disable-shared --prefix=$DEPS_PATH || exit -1
make -j$(nproc) || exit -1
make install
cd -

# download and build opencv since we need the static library
curl -L https://github.com/Itseez/opencv/archive/$OPENCV_VERSION.zip -o $DEPS_PATH/opencv.zip
unzip $DEPS_PATH/opencv.zip -d $DEPS_PATH
mkdir $DEPS_PATH/opencv-$OPENCV_VERSION/build
cd $DEPS_PATH/opencv-$OPENCV_VERSION/build
cmake -D WITH_1394=OFF \
      -D WITH_OPENEXR=OFF \
      -D WITH_AVFOUNDATION=OFF \
      -D WITH_QTKit=OFF \
      -D WITH_CUDA=OFF \
      -D WITH_VTK=OFF \
      -D WITH_CUFFT=OFF \
      -D WITH_CUBLAS=OFF \
      -D WITH_NVCUVID=OFF \
      -D WITH_EIGEN=ON \
      -D WITH_VFW=OFF \
      -D WITH_FFMPEG=OFF \
      -D WITH_GSTREAMER=OFF \
      -D WITH_GTK=OFF \
      -D WITH_JASPER=OFF \
      -D WITH_JPEG=ON \
      -D WITH_PNG=ON \
      -D WITH_QUICKTIME=OFF \
      -D WITH_TBB=OFF \
      -D WITH_TIFF=OFF \
      -D WITH_V4L=OFF \
      -D WITH_LIBV4L=OFF \
      -D WITH_DSHOW=OFF \
      -D WITH_MSMF=OFF \
      -D WITH_OPENCL=OFF \
      -D WITH_OPENCLAMDFFT=OFF \
      -D WITH_OPENCLAMDBLAS=OFF \
      -D BUILD_SHARED_LIBS=OFF \
      -D BUILD_opencv_apps=OFF \
      -D BUILD_opencv_gpu=OFF \
      -D BUILD_opencv_video=OFF \
      -D BUILD_opencv_contrib=OFF \
      -D BUILD_opencv_nonfree=OFF \
      -D BUILD_opencv_flann=OFF \
      -D BUILD_opencv_features2d=OFF \
      -D BUILD_opencv_calib3d=OFF \
      -D BUILD_opencv_objdetect=OFF \
      -D BUILD_opencv_ml=OFF \
      -D BUILD_opencv_photo=OFF \
      -D BUILD_DOCS=OFF \
      -D BUILD_PACKAGE=OFF \
      -D CMAKE_BUILD_TYPE=RELEASE \
      -D CMAKE_INSTALL_PREFIX=$DEPS_PATH .. || exit -1
make -j $(nproc) || exit -1
make install # user will always have access to home, so no sudo needed
cd -

# Although .so building is explicitly turned off for most libraries, sometimes
# they still get created. So, remove them just to make sure they don't
# interfere, or otherwise we might get libmxnet.so that is not self-contained.
rm $DEPS_PATH/{lib,lib64}/*.{so,so.0}

git clone --recursive https://github.com/dmlc/mxnet.git mxnet-build

# Go to the parent path and build mxnet
cp pip_$(uname | tr '[:upper:]' '[:lower:]')_cpu.mk mxnet-build/config.mk
cd mxnet-build
make -j $(nproc) || exit -1

# Generate wheel. The output is in the mxnet/tools/pip_package/dist path.
cd ../
# python setup.py bdist_wheel
