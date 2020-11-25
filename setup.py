import setuptools

with open("README.md", "r") as fh:
    long_description = fh.read()

setuptools.setup(
    name='kpick', 
    version='1.0.0',
    author="Trung M. Bui",
    author_email="bmtrungvp@gmail.com",
    description="An AI picking package",
    long_description=long_description,
    long_description_content_type="text/markdown",
    url="https://github.com/mtbui2010",
    packages= setuptools.find_packages(),
    classifiers=[
        "Programming Language :: Python :: 3",
        "License :: OSI Approved :: MIT License",
        "Operating System :: OS Independent",
    ],
    python_requires='>=3.6',
    #entry_points = {
    #      'console_scripts': ['ttcv_sample=ttcv.samples.select_sample:run'],
    # }
    license='MIT', 
    keywords = ['AI','VISION', 'GRASP DETECTION'],
    install_requires=[            
          'numpy',
        'opencv-python',
         'scipy',
         'matplotlib',
   	'ttcv',
        'torch==1.4.0',
        'torchvision==0.5.0',
	'progress',
	'ray',
     ],
)	
