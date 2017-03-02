#!/usr/bin/env bash
cd /mxnet/tests/nightly
sudo python test_ipynb.py

echo "Test Summary Start"
sudo cat test_summary.txt
echo "Test Summary End"
