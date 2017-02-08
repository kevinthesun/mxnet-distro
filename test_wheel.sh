#!/usr/bin/env bash
set -eo pipefail
sudo pip install dist/*.whl
python sanity_test.py
