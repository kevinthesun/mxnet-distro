#!/usr/bin/env bash
if [ $# -lt 1 ]; then
    echo "Usage: make_standalone_libmxnet.sh <VARIANT>[CPU|MKL|CU75|CU80]"
    exit 1
fi

#Install Dependencies
apt-get update
sudo apt-get install -y build-essential
sudo apt-get install -y cmake git libgtk2.0-dev pkg-config libavcodec-dev libavformat-dev libswscale-dev
sudo apt-get install -y python-dev python-numpy libtbb2 libtbb-dev libjpeg-dev libpng-dev libtiff-dev libjasper-dev libdc1394-22-dev

# Variants include CPU, MKL, CU75 and CU80
# darwin only supports CPU version which depends on and builds openblas.
# on linux, CPU version also depends on openblas.
# MKL version depends on mklml.
# CU75 version depends on and downloads cuda-7.5 and cudnn-5.1.
# CU80 version depends on and downloads cuda-8.0 and cudnn-5.1.
VARIANT=$(echo $1 | tr '[:upper:]' '[:lower:]')
PLATFORM=$(uname | tr '[:upper:]' '[:lower:]')

make_config=pip_${PLATFORM}_${VARIANT}.mk
if [[ ! -f $make_config ]]; then
    echo "Couldn't find make config $make_config for the current settings."
    exit 1
fi

# Variant-specific dependencies:
if [[ $PLATFORM == 'linux' ]]; then
    export OPENBLAS_VERSION=0.2.19
    # TODO uncomment when starting to use mkldnn
    # if [[ $VARIANT == 'mkl' ]]; then
        # export MKLML_VERSION='2017.0.2.20170209'
        # export MKLDNN_VERSION='0.5'
    if [[ $VARIANT == 'cu80' ]]; then
        export CUDA_VERSION='8.0.61-1'
        export LIBCUDA_VERSION='375.26-0ubuntu1'
        export LIBCUDNN_VERSION='5.1.10-1+cuda8.0'
    elif [[ $VARIANT == 'cu75' ]]; then
        export CUDA_VERSION='7.5-18'
        export LIBCUDA_VERSION='375.26-0ubuntu1'
        export LIBCUDNN_VERSION='5.1.10-1+cuda7.5'
    fi
elif [[ $PLATFORM == 'darwin' ]]; then
    export OPENBLAS_VERSION=0.2.19
fi

# Set up path as temporary working directory
export DEPS_PATH=$PWD/deps
rm -rf $DEPS_PATH
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
export NUM_PROC
echo "Using $NUM_PROC parallel jobs in building."


# Set up shared dependencies:
./make_shared_dependencies.sh
./make_openblas.sh

# Although .so/.dylib building is explicitly turned off for most libraries, sometimes
# they still get created. So, remove them just to make sure they don't
# interfere, or otherwise we might get libmxnet.so that is not self-contained.
# For CUDA, since we cannot redistribute the shared objects or perform static linking,
# we DO want to keep the shared objects around, hence performing deletion before cuda setup.
rm $DEPS_PATH/{lib,lib64}/*.{so,so.*,dylib}

if [[ $PLATFORM == 'linux' ]]; then

    # TODO when using mkldnn download and install mkl and mkldnn, and set paths
    # if [[ $VARIANT == 'mkl' ]]; then
        # ./make_mklml_mkldnn.sh
    if [[ ( $VARIANT == 'cu75' ) || ( $VARIANT == 'cu80' ) ]]; then
        # download and install cuda and cudnn, and set paths
        ./setup_gpu_build_tools.sh
        CUDA_MAJOR_VERSION=$(echo $CUDA_VERSION | tr '-' '.' | cut -d. -f1,2)
        NVIDIA_MAJOR_VERSION=$(echo $LIBCUDA_VERSION | cut -d. -f1)
        export PATH=${PATH}:$DEPS_PATH/usr/local/cuda-$CUDA_MAJOR_VERSION/bin
        export CPLUS_INCLUDE_PATH=${CPLUS_INCLUDE_PATH}:$DEPS_PATH/usr/local/cuda-$CUDA_MAJOR_VERSION/include
        export C_INCLUDE_PATH=${C_INCLUDE_PATH}:$DEPS_PATH/usr/local/cuda-$CUDA_MAJOR_VERSION/include
        export LIBRARY_PATH=${LIBRARY_PATH}:$DEPS_PATH/usr/local/cuda-$CUDA_MAJOR_VERSION/lib64:$DEPS_PATH/usr/lib/x86_64-linux-gnu:$DEPS_PATH/usr/lib/nvidia-$NVIDIA_MAJOR_VERSION
        export LD_LIBRARY_PATH=${LD_LIBRARY_PATH}:$DEPS_PATH/usr/local/cuda-$CUDA_MAJOR_VERSION/lib64:$DEPS_PATH/usr/lib/x86_64-linux-gnu:$DEPS_PATH/usr/lib/nvidia-$NVIDIA_MAJOR_VERSION
    fi
fi

# If a travis build is from a tag, use this tag for fetching the corresponding release
if [[ ! -z $TRAVIS_TAG ]]; then
    GIT_ADDITIONAL_FLAGS="-b $TRAVIS_TAG"
fi
rm -rf mxnet
git clone https://github.com/dmlc/mxnet.git --recursive

echo "Now building mxnet..."
cp pip_$(uname | tr '[:upper:]' '[:lower:]')_${VARIANT}.mk mxnet/config.mk
cd mxnet
make -j $NUM_PROC || exit -1;
cd ../

if [[ $VARIANT == 'mkl' ]]; then
    cp deps/lib/libmklml_intel.so mxnet/lib
    cp deps/lib/libiomp5.so mxnet/lib
    cp deps/license.txt mxnet/MKLML_LICENSE
fi

# Print the linked objects on libmxnet.so
echo "Checking linked objects on libmxnet.so..."
if [[ ! -z $(command -v readelf) ]]; then
    readelf -d mxnet/lib/libmxnet.so
elif [[ ! -z $(command -v otool) ]]; then
    otool -L mxnet/lib/libmxnet.so
else
    echo "Not available"
fi

# Test notebooks
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
git clone https://github.com/kevinthesun/mxnet.git mxnet-nbtest
cd mxnet-nbtest/tests/nightly
git checkout --track origin/UbuntuNotebooktest
git clone https://github.com/kevinthesun/mxnet-notebooks.git
cd mxnet-notebooks
git checkout --track origin/CleanNotebook
cd ..
python test_ipynb.py

echo "Test Summary Start"
cat test_summary.txt
echo "Test Summary End"
