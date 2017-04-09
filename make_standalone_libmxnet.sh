#!/usr/bin/env bash
apt-get -y install python-opencv
apt-get -y install ipython ipython-notebook
apt-get -y install graphviz
python -m pip install -U pip
pip install --upgrade setuptools
pip install jupyter
pip install graphviz
pip install matplotlib
pip install sklearn

git clone --recursive https://github.com/dmlc/mxnet.git mxnet-build $GIT_ADDITIONAL_FLAGS

echo "Now building mxnet..."
cd mxnet-build
cp make/config.mk .
make -j8 USE_BLAS=openblas USE_CUDA=1 USE_CUDA_PATH=/usr/local/cuda USE_CUDNN=1
cd python
python setup.py install


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
python -u test_ipynb.py
