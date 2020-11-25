from setuptools import setup
from Cython.Build import cythonize
setup(ext_modules = cythonize(['grip_evaluation.py', 'suction_evaluation.py']))