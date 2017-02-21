#!/usr/bin/env bash
if [ $# -lt 1 ]; then
echo "Usage: make_standalone_libmxnet.sh <VARIANT>[CPU|CU75|CU80]"
exit 1
fi

# Variants include CPU, CU75 and CU80
# CPU version depends on and builds openblas.
# CU75 version depends on and downloads cuda-7.5 and cudnn-5.1.
# CU80 version depends on and downloads cuda-8.0 and cudnn-5.1.
VARIANT=$(echo $1 | tr '[:upper:]' '[:lower:]')


# Dependencies can be updated here. Be sure to verify the download links
# and build logics before changing.
# Variant-specific dependencies:
if [[ $VARIANT == 'cu80' ]]; then
CUDA_VERSION='8.0.61-1'
LIBCUDA_VERSION='375.26-0ubuntu1'
LIBCUDNN_VERSION='5.1.10-1+cuda8.0'
elif [[ $VARIANT == 'cu75' ]]; then
CUDA_VERSION='7.5-18'
LIBCUDA_VERSION='375.26-0ubuntu1'
LIBCUDNN_VERSION='5.1.10-1+cuda7.5'
fi

# Dependencies that are shared by variants are:
ZLIB_VERSION=1.2.6
OPENBLAS_VERSION=0.2.19
JPEG_VERSION=8.4.0
PNG_VERSION=1.5.10
TIFF_VERSION=3.8.2
OPENCV_VERSION=3.2.0

# Set up path as temporary working directory
DEPS_PATH=$PWD/deps
rm -rf $PWD/deps
mkdir $DEPS_PATH

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


# Set up shared dependencies:
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
curl -s -L https://github.com/opencv/opencv/archive/$OPENCV_VERSION.zip -o $DEPS_PATH/opencv.zip
unzip -q $DEPS_PATH/opencv.zip -d $DEPS_PATH
mkdir $DEPS_PATH/opencv-$OPENCV_VERSION/build
cd $DEPS_PATH/opencv-$OPENCV_VERSION/build
cmake -q \
-D OPENCV_ENABLE_NONFREE=OFF \
-D WITH_1394=OFF \
-D WITH_ARAVIS=ON \
-D WITH_AVFOUNDATION=OFF \
-D WITH_CAROTENE=OFF \
-D WITH_CLP=OFF \
-D WITH_CSTRIPES=OFF \
-D WITH_CUBLAS=OFF \
-D WITH_CUDA=OFF \
-D WITH_CUFFT=OFF \
-D WITH_DIRECTX=OFF \
-D WITH_DSHOW=OFF \
-D WITH_EIGEN=OFF \
-D WITH_FFMPEG=OFF \
-D WITH_GDAL=OFF \
-D WITH_GDCM=ON \
-D WITH_GIGEAPI=ON \
-D WITH_GPHOTO2=OFF \
-D WITH_GSTREAMER=OFF \
-D WITH_GSTREAMER_0_10=OFF \
-D WITH_GTK=OFF \
-D WITH_IMAGEIO=OFF \
-D WITH_INTELPERC=OFF \
-D WITH_IPP=OFF \
-D WITH_IPP_A=OFF \
-D WITH_JASPER=OFF \
-D WITH_JPEG=ON \
-D WITH_LAPACK=OFF \
-D WITH_LIBV4L=OFF \
-D WITH_MATLAB=OFF \
-D WITH_MSMF=OFF \
-D WITH_OPENCL=OFF \
-D WITH_OPENCLAMDBLAS=OFF \
-D WITH_OPENCLAMDFFT=OFF \
-D WITH_OPENCL_SVM=OFF \
-D WITH_OPENEXR=OFF \
-D WITH_OPENGL=OFF \
-D WITH_OPENMP=OFF \
-D WITH_OPENNI2=OFF \
-D WITH_OPENNI=OFF \
-D WITH_OPENVX=OFF \
-D WITH_PNG=ON \
-D WITH_PTHREADS_PF=OFF \
-D WITH_PVAPI=ON \
-D WITH_QT=OFF \
-D WITH_QTKIT=OFF \
-D WITH_QUICKTIME=OFF \
-D WITH_TBB=OFF \
-D WITH_TIFF=ON \
-D WITH_UNICAP=OFF \
-D WITH_V4L=OFF \
-D WITH_VA=OFF \
-D WITH_VA_INTEL=OFF \
-D WITH_VFW=OFF \
-D WITH_VTK=OFF \
-D WITH_WEBP=OFF \
-D WITH_WIN32UI=OFF \
-D WITH_XIMEA=OFF \
-D WITH_XINE=OFF \
-D BUILD_SHARED_LIBS=OFF \
-D BUILD_opencv_apps=OFF \
-D BUILD_ANDROID_EXAMPLES=OFF \
-D BUILD_DOCS=OFF \
-D BUILD_EXAMPLES=OFF \
-D BUILD_PACKAGE=OFF \
-D BUILD_PERF_TESTS=OFF \
-D BUILD_TESTS=OFF \
-D BUILD_WITH_DEBUG_INFO=OFF \
-D BUILD_WITH_DYNAMIC_IPP=OFF \
-D BUILD_FAT_JAVA_LIB=OFF \
-D BUILD_CUDA_STUBS=OFF \
-D BUILD_ZLIB=OFF \
-D BUILD_TIFF=OFF \
-D BUILD_JASPER=OFF \
-D BUILD_JPEG=OFF \
-D BUILD_PNG=OFF \
-D BUILD_OPENEXR=OFF \
-D BUILD_TBB=OFF \
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
-D BUILD_opencv_videostab=OFF \
-D BUILD_opencv_world=OFF \
-D BUILD_opencv_highgui=OFF \
-D BUILD_opencv_viz=OFF \
-D BUILD_opencv_videoio=OFF \
-D CMAKE_LIBRARY_PATH=$DEPS_PATH/lib \
-D CMAKE_INCLUDE_PATH=$DEPS_PATH/include \
-D CMAKE_BUILD_TYPE=RELEASE \
-D CMAKE_INSTALL_PREFIX=$DEPS_PATH .. || exit -1;
make --quiet -j $NUM_PROC || exit -1;
make install; # user will always have access to home, so no sudo needed
cd -;

# @szha: this is a hack to use the compatibility header
cat $DEPS_PATH/include/opencv2/imgcodecs/imgcodecs_c.h >> $DEPS_PATH/include/opencv2/imgcodecs.hpp

# Although .so/.dylib building is explicitly turned off for most libraries, sometimes
# they still get created. So, remove them just to make sure they don't
# interfere, or otherwise we might get libmxnet.so that is not self-contained.
# For CUDA, since we cannot redistribute the shared objects or perform static linking,
# we DO want to keep the shared objects around, hence performing deletion before cuda setup.
rm $DEPS_PATH/{lib,lib64}/*.{so,so.*,dylib}

# Set up gpu-specific dependencies:
if [[ ( $VARIANT == 'cu75' ) || ( $VARIANT == 'cu80' ) ]]; then

# download and install cuda and cudnn
./setup_gpu_build_tools.sh $DEPS_PATH $CUDA_VERSION $LIBCUDA_VERSION $LIBCUDNN_VERSION

# setup path
CUDA_MAJOR_VERSION=$(echo $CUDA_VERSION | tr '-' '.' | cut -d. -f1,2)
NVIDIA_MAJOR_VERSION=$(echo $LIBCUDA_VERSION | cut -d. -f1)
export PATH=${PATH}:$DEPS_PATH/usr/local/cuda-$CUDA_MAJOR_VERSION/bin
export CPLUS_INCLUDE_PATH=${CPLUS_INCLUDE_PATH}:$DEPS_PATH/usr/local/cuda-$CUDA_MAJOR_VERSION/include
export C_INCLUDE_PATH=${C_INCLUDE_PATH}:$DEPS_PATH/usr/local/cuda-$CUDA_MAJOR_VERSION/include
export LIBRARY_PATH=${LIBRARY_PATH}:$DEPS_PATH/usr/local/cuda-$CUDA_MAJOR_VERSION/lib64:$DEPS_PATH/usr/lib/x86_64-linux-gnu:$DEPS_PATH/usr/lib/nvidia-$NVIDIA_MAJOR_VERSION
export LD_LIBRARY_PATH=${LD_LIBRARY_PATH}:$DEPS_PATH/usr/local/cuda-$CUDA_MAJOR_VERSION/lib64:$DEPS_PATH/usr/lib/x86_64-linux-gnu:$DEPS_PATH/usr/lib/nvidia-$NVIDIA_MAJOR_VERSION

fi

# If a travis build is from a tag, use this tag for fetching the corresponding release
if [[ ! -z $TRAVIS_TAG ]]; then
GIT_ADDITIONAL_FLAGS="-b $TRAVIS_TAG"
fi
rm -rf mxnet
apt-get install git
git clone https://github.com/dmlc/mxnet.git --recursive

echo "Now building mxnet..."
cp pip_$(uname | tr '[:upper:]' '[:lower:]')_${VARIANT}.mk mxnet/config.mk
cd mxnet
make -j $NUM_PROC || exit -1;
cd python
python setup.py install
cd ../../

# Print the linked objects on libmxnet.so
echo "Checking linked objects on libmxnet.so..."
if [[ ! -z $(command -v readelf) ]]; then
    readelf -d mxnet/lib/libmxnet.so
elif [[ ! -z $(command -v otool) ]]; then
    otool -L mxnet/lib/libmxnet.so
else
    echo "Not available"
fi

echo "Test Jupyter notebook"
apt-get -y install ipython ipython-notebook
python -m pip install -U pip
pip install jupyter
apt-get -y install graphviz
pip install graphviz
pip install --upgrade setuptools
pip install matplotlib
pip install sklearn
pip install opencv-python
cd mxnet/tests/nightly
git clone https://github.com/kevinthesun/mxnet.git
cd mxnet/tests/nightly
git checkout --track origin/UbuntuNotebooktest
git clone https://github.com/kevinthesun/mxnet-notebooks.git
cd mxnet-notebooks
git checkout --track origin/CleanNotebook
cd ..
python test_ipynb.py
