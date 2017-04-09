#!/usr/bin/env bash
sudo apt-get update
sudo apt-get -y install git
sudo apt-get -y install python-opencv
sudo apt-get -y install ipython ipython-notebook
sudo apt-get -y install graphviz
sudo python -m pip install -U pip
sudo pip install --upgrade setuptools
sudo pip install jupyter
sudo pip install graphviz
sudo pip install matplotlib
sudo pip install sklearn

git clone --recursive https://github.com/dmlc/mxnet.git mxnet-build $GIT_ADDITIONAL_FLAGS

echo "Now building mxnet..."
cd mxnet-build
cp make/config.mk .
make -j8 USE_CUDA=1 USE_CUDA_PATH=/usr/local/cuda USE_CUDNN=1 || exit 1
cd python
sudo python setup.py install


# Test notebooks
cd /
echo "Test Jupyter notebook"
git clone https://github.com/kevinthesun/mxnet.git
cd mxnet/tests/nightly
git checkout --track origin/UbuntuNotebooktest
git clone https://github.com/kevinthesun/mxnet-notebooks.git
cd mxnet-notebooks
git checkout --track origin/CleanNotebook
cd ..
sudo python -u test_ipynb.py
