# pylint: disable=invalid-name, exec-used
"""Setup mxnet package."""
from __future__ import absolute_import
import os
import sys
import shutil
import platform

if platform.system() == 'Linux':
    sys.argv.append('--plat-name=manylinux1_x86_64')

from setuptools import setup, find_packages
from setuptools.dist import Distribution

# We can not import `mxnet.info.py` in setup.py directly since mxnet/__init__.py
# Will be invoked which introduces dependences
CURRENT_DIR = os.path.dirname(__file__)
libinfo_py = os.path.join(CURRENT_DIR, 'mxnet-build/python/mxnet/libinfo.py')
libinfo = {'__file__': libinfo_py}
exec(compile(open(libinfo_py, "rb").read(), libinfo_py, 'exec'), libinfo, libinfo)

LIB_PATH = libinfo['find_lib_path']()
__version__ = libinfo['__version__']

class BinaryDistribution(Distribution):
    def has_ext_modules(self):
        return True


DEPENDENCIES = [
    'numpy',
]

shutil.rmtree(os.path.join(CURRENT_DIR, 'mxnet'), ignore_errors=True)
shutil.copytree(os.path.join(CURRENT_DIR, 'mxnet-build/python/mxnet'),
                os.path.join(CURRENT_DIR, 'mxnet'))
shutil.copy(LIB_PATH[0], os.path.join(CURRENT_DIR, 'mxnet'))

package_name = 'mxnet'
if 'mxnet_variant' in os.environ and os.environ['mxnet_variant'].lower() == 'gpu':
    package_name = 'mxnet_gpu'

setup(name=package_name,
      version=__version__,
      description=open('README.md').read(),
      zip_safe=False,
      packages=find_packages(),
      package_data={'mxnet': [os.path.join('mxnet', os.path.basename(LIB_PATH[0]))]},
      include_package_data=True,
      install_requires=DEPENDENCIES,
      distclass=BinaryDistribution,
      url='https://github.com/dmlc/mxnet')
