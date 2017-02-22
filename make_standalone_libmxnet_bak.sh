#!/usr/bin/env bash
python -m pip install -U pip
python2.7 -m pip install -U mxnet-cu75

# Test notebooks
cd /
echo "Test Jupyter notebook"
apt-get -y install ipython ipython-notebook
pip install --upgrade setuptools
pip install jupyter
apt-get -y install graphviz
pip install graphviz
pip install matplotlib
pip install sklearn
python2.7 -m pip install opencv-python
git clone https://github.com/kevinthesun/mxnet.git
cd mxnet/tests/nightly
git checkout --track origin/UbuntuNotebooktest
git clone https://github.com/kevinthesun/mxnet-notebooks.git
cd mxnet-notebooks
git checkout --track origin/CleanNotebook
cd ../
rm test_config.txt
mv test_config_bak.txt test_config.txt
python test_ipynb.py

echo "Test Summary Start"
cat test_summary.txt
echo "Test Summary End"
