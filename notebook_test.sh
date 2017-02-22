#!/usr/bin/env bash
cd /mxnet/tests/nightly
python test_ipynb.py

echo "Test Summary Start"
cat test_summary.txt
echo "Test Summary End"
