#!/usr/bin/env bash
set -eo pipefail

pip install -U --force-reinstall dist/*.whl
python sanity_test.py

# @szha: this is a workaround for travis-ci#6522
set +e
