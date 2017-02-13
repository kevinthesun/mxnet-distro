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
with open('PYPI_README.md') as readme_file:
    long_description = readme_file.read()

variant = os.environ['mxnet_variant'].upper()
if variant == 'GPU':
    package_name = 'mxnet_gpu'

with open('{0}_ADDITIONAL.md'.format(variant)) as variant_doc:
    long_description = long_description + variant_doc.read()

# pypi only supports rst, so use pandoc to convert
import pypandoc
long_description = pypandoc.convert_text(long_description, 'rst', 'md')

setup(name=package_name,
      version=__version__,
      long_description=long_description,
      description='MXNet is a deep learning framework designed for both efficiency and flexibility. It allows you to mix the flavours of deep learning programs together to maximize the efficiency and your productivity.',
      zip_safe=False,
      packages=find_packages(),
      package_data={'mxnet': [os.path.join('mxnet', os.path.basename(LIB_PATH[0]))]},
      include_package_data=True,
      install_requires=DEPENDENCIES,
      distclass=BinaryDistribution,
      license='Apache 2.0',
      url='https://github.com/dmlc/mxnet')
