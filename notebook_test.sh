#!/usr/bin bash
cd /mxnet/tests/nightly/mxnet-notebooks/python/basic
python symbol.py
cd ../../../
python test_ipynb.py

echo "Test Summary Start"
cat test_summary.txt
echo "Test Summary End"
