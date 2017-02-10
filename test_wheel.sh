#!/usr/bin/env bash
set -eo pipefail

if [[ ! -z $(command -v pip3) ]]; then
  PIP=pip3
else
  PIP=pip
fi
$PIP install -U --force-reinstall dist/*.whl
python sanity_test.py

# @szha: this is a workaround for travis-ci#6522
set +e
