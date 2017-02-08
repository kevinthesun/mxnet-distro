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
export FC="gforgran"

# Discover number of processors
NUM_PROC=1
if [[ ! -z $(command -v nproc) ]]; then
    NUM_PROC=$(nproc)
elif [[ ! -z $(command -v sysctl) ]]; then
    NUM_PROC=$(sysctl -n hw.ncpu)
else
    echo "Can't discover number of cores."
fi
echo "Using $NUM_PROC parallel jobs in building."


# Download and build zlib
echo "Building zlib..."
curl -s -L https://github.com/LuaDist/zlib/archive/$ZLIB_VERSION.zip -o $DEPS_PATH/zlib.zip
unzip -q $DEPS_PATH/zlib.zip -d $DEPS_PATH
mkdir $DEPS_PATH/zlib-$ZLIB_VERSION/build
cd $DEPS_PATH/zlib-$ZLIB_VERSION/build
cmake -q \
      -D CMAKE_BUILD_TYPE=RELEASE \
      -D CMAKE_INSTALL_PREFIX=$DEPS_PATH \
      -D BUILD_SHARED_LIBS=OFF .. || exit -1;
make --quiet -j $NUM_PROC || exit -1;
make install;
cd -;

# download and build openblas
echo "Building openblas..."
curl -s -L https://github.com/xianyi/OpenBLAS/archive/v$OPENBLAS_VERSION.zip -o $DEPS_PATH/openblas.zip
unzip -q $DEPS_PATH/openblas.zip -d $DEPS_PATH
cd $DEPS_PATH/OpenBLAS-$OPENBLAS_VERSION
make --quiet -j $NUM_PROC || exit -1;
make PREFIX=$DEPS_PATH install;
cd -;
ln -s $DEPS_PATH/lib/libopenblas_haswellp-r0.2.19.a $DEPS_PATH/lib/libcblas.a;

# download and build libjpeg
echo "Building libjpeg..."
curl -s -L https://github.com/LuaDist/libjpeg/archive/$JPEG_VERSION.zip -o $DEPS_PATH/libjpeg.zip
unzip -q $DEPS_PATH/libjpeg.zip -d $DEPS_PATH
cd $DEPS_PATH/libjpeg-$JPEG_VERSION
./configure --quiet --disable-shared --prefix=$DEPS_PATH || exit -1
make --quiet -j $NUM_PROC || exit -1;
make test || exit -1;
make install;
cd -

# download and build libpng
echo "Building libpng..."
curl -s -L https://github.com/LuaDist/libpng/archive/$PNG_VERSION.zip -o $DEPS_PATH/libpng.zip
unzip -q $DEPS_PATH/libpng.zip -d $DEPS_PATH
mkdir $DEPS_PATH/libpng-$PNG_VERSION/build
cd $DEPS_PATH/libpng-$PNG_VERSION/build
cmake -q \
      -D CMAKE_BUILD_TYPE=RELEASE \
      -D CMAKE_INSTALL_PREFIX=$DEPS_PATH \
      -D PNG_CONFIGURE_LIBPNG=-fPIC \
      -D BUILD_SHARED_LIBS=OFF .. || exit -1;
make --quiet -j $NUM_PROC || exit -1;
make install
cd -

# download and build libtiff
echo "Building libtiff..."
curl -s -L https://github.com/LuaDist/libtiff/archive/$TIFF_VERSION.zip -o $DEPS_PATH/libtiff.zip
unzip -q $DEPS_PATH/libtiff.zip -d $DEPS_PATH
cd $DEPS_PATH/libtiff-$TIFF_VERSION
./configure --quiet --disable-shared --prefix=$DEPS_PATH || exit -1;
make --quiet -j $NUM_PROC || exit -1;
make install
cd -

# download and build opencv since we need the static library
echo "Building opencv..."
curl -s -L https://github.com/Itseez/opencv/archive/$OPENCV_VERSION.zip -o $DEPS_PATH/opencv.zip
unzip -q $DEPS_PATH/opencv.zip -d $DEPS_PATH
mkdir $DEPS_PATH/opencv-$OPENCV_VERSION/build
cd $DEPS_PATH/opencv-$OPENCV_VERSION/build
cmake -q \
      -D WITH_1394=OFF \
      -D WITH_AVFOUNDATION=OFF \
      -D WITH_CUBLAS=OFF \
      -D WITH_CUDA=OFF \
      -D WITH_CUFFT=OFF \
      -D WITH_DSHOW=OFF \
      -D WITH_EIGEN=ON \
      -D WITH_FFMPEG=OFF \
      -D WITH_GSTREAMER=OFF \
      -D WITH_GTK=OFF \
      -D WITH_IMAGEIO=OFF \
      -D WITH_JASPER=OFF \
      -D WITH_JPEG=ON \
      -D WITH_LIBV4L=OFF \
      -D WITH_MSMF=OFF \
      -D WITH_NVCUVID=OFF \
      -D WITH_OPENCL=OFF \
      -D WITH_OPENCLAMDBLAS=OFF \
      -D WITH_OPENCLAMDFFT=OFF \
      -D WITH_OPENEXR=OFF \
      -D WITH_PNG=ON \
      -D WITH_QT=OFF \
      -D WITH_QUICKTIME=OFF \
      -D WITH_TBB=OFF \
      -D WITH_TIFF=ON \
      -D WITH_V4L=OFF \
      -D WITH_VFW=OFF \
      -D WITH_VTK=OFF \
      -D BUILD_DOCS=OFF \
      -D BUILD_EXAMPLES=OFF \
      -D BUILD_FAT_JAVA_LIB=OFF \
      -D BUILD_JASPER=OFF \
      -D BUILD_JPEG=OFF \
      -D BUILD_OPENEXR=OFF \
      -D BUILD_PACKAGE=OFF \
      -D BUILD_PNG=OFF \
      -D BUILD_SHARED_LIBS=OFF \
      -D BUILD_TIFF=OFF \
      -D BUILD_ZLIB=OFF \
      -D BUILD_opencv_apps=OFF \
      -D BUILD_opencv_calib3d=OFF \
      -D BUILD_opencv_contrib=OFF \
      -D BUILD_opencv_features2d=OFF \
      -D BUILD_opencv_flann=OFF \
      -D BUILD_opencv_gpu=OFF \
      -D BUILD_opencv_ml=OFF \
      -D BUILD_opencv_nonfree=OFF \
      -D BUILD_opencv_objdetect=OFF \
      -D BUILD_opencv_photo=OFF \
      -D BUILD_opencv_python=OFF \
      -D BUILD_opencv_video=OFF \
      -D CMAKE_LIBRARY_PATH=$DEPS_PATH/lib \
      -D CMAKE_BUILD_TYPE=RELEASE \
      -D CMAKE_INSTALL_PREFIX=$DEPS_PATH .. || exit -1
make --quiet -j $NUM_PROC || exit -1
make install # user will always have access to home, so no sudo needed
cd -


# Although .so/.dylib building is explicitly turned off for most libraries, sometimes
# they still get created. So, remove them just to make sure they don't
# interfere, or otherwise we might get libmxnet.so that is not self-contained.
rm $DEPS_PATH/{lib,lib64}/*.{so,so.0,dylib}

# Fix opencv.pc bug on osx https://github.com/opencv/opencv/issues/5018
sed -ie 's|-l-framework|-framework|g' $DEPS_PATH/lib/pkgconfig/opencv.pc

rm -rf mxnet-build
git clone --recursive https://github.com/dmlc/mxnet.git mxnet-build


# Go to the parent path and build mxnet
echo "Now building mxnet..."
cp pip_$(uname | tr '[:upper:]' '[:lower:]')_cpu.mk mxnet-build/config.mk
cd mxnet-build
make -j $NUM_PROC || exit -1;
cd ../

# Make wheel for testing
python setup.py bdist_wheel

# Now it's ready to test.
# After testing, Travis will build the wheel again
# The output will be in the 'dist' path.
