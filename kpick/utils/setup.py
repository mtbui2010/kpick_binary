from setuptools import setup
from Cython.Build import cythonize
setup(ext_modules = cythonize(['grasp_utils.py', 'grip_utils.py', 'suction_utils.py', 'suction_utils_v2.py']))