from setuptools import setup
from Cython.Build import cythonize
setup(ext_modules = cythonize(['train.py', 'train_picking.py']))