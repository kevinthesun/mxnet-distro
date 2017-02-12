#!/usr/bin/env bash
# Install nvcc and setup environment variable
set -e
if [ $# -lt 1 ]; then
    echo "Usage: <NVCC_PREFIX> <CUDA_VERSION> <LIBCUDA_VERSION> <CUDNN_VERSION>"
    exit 1
fi

prefix=$1
cuda=$2
libcuda=$3
libcudnn=$4

cuda_major=$(echo $cuda | cut -d. -f1,2 | tr '.' '-')
libcuda_major=$(echo $libcuda | cut -d. -f1)
libcudnn_major=$(echo $libcudnn | cut -d. -f1)

# list of debs to download from nvidia

files=( \
  "http://developer.download.nvidia.com/compute/cuda/repos/ubuntu1404/x86_64/cuda-core-${cuda_major}_${cuda}_amd64.deb" \
  "http://developer.download.nvidia.com/compute/cuda/repos/ubuntu1404/x86_64/cuda-cublas-${cuda_major}_${cuda}_amd64.deb" \
  "http://developer.download.nvidia.com/compute/cuda/repos/ubuntu1404/x86_64/cuda-cublas-dev-${cuda_major}_${cuda}_amd64.deb" \
  "http://developer.download.nvidia.com/compute/cuda/repos/ubuntu1404/x86_64/cuda-cudart-${cuda_major}_${cuda}_amd64.deb" \
  "http://developer.download.nvidia.com/compute/cuda/repos/ubuntu1404/x86_64/cuda-cudart-dev-${cuda_major}_${cuda}_amd64.deb" \
  "http://developer.download.nvidia.com/compute/cuda/repos/ubuntu1404/x86_64/cuda-curand-${cuda_major}_${cuda}_amd64.deb" \
  "http://developer.download.nvidia.com/compute/cuda/repos/ubuntu1404/x86_64/cuda-curand-dev-${cuda_major}_${cuda}_amd64.deb" \
  "http://developer.download.nvidia.com/compute/cuda/repos/ubuntu1404/x86_64/cuda-nvrtc-${cuda_major}_${cuda}_amd64.deb" \
  "http://developer.download.nvidia.com/compute/cuda/repos/ubuntu1404/x86_64/cuda-nvrtc-dev-${cuda_major}_${cuda}_amd64.deb" \
  "http://developer.download.nvidia.com/compute/cuda/repos/ubuntu1404/x86_64/cuda-misc-headers-${cuda_major}_${cuda}_amd64.deb" \
  "http://developer.download.nvidia.com/compute/cuda/repos/ubuntu1404/x86_64/libcuda1-${libcuda_major}_${libcuda}_amd64.deb" \
  "http://developer.download.nvidia.com/compute/cuda/repos/ubuntu1404/x86_64/nvidia-${libcuda_major}_${libcuda}_amd64.deb" \
  "http://developer.download.nvidia.com/compute/machine-learning/repos/ubuntu1404/x86_64/libcudnn${libcudnn_major}-dev_5.1.10-1+cuda8.0_amd64.deb" \
  "http://developer.download.nvidia.com/compute/machine-learning/repos/ubuntu1404/x86_64/libcudnn${libcudnn_major}_5.1.10-1+cuda8.0_amd64.deb" \
)

for item in ${files[*]}
do
    echo "Installing $item"
    curl -sL ${item} -o package.deb
    dpkg -X package.deb ${prefix}
    rm package.deb
done

cp deps/usr/include/x86_64-linux-gnu/cudnn_v5.h deps/include/cudnn.h
ln -s libcudnn.so.5 deps/usr/lib/x86_64-linux-gnu/libcudnn.so

# @szha: this is a workaround for travis-ci#6522
set +e
