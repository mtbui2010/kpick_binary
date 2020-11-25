from setuptools import setup
from Cython.Build import cythonize
setup(ext_modules = cythonize(['dataset.py', 'grasp_cifar10_dber.py', 'grip_cifar10_dber.py', 'suction_cifar10_dber.py']))