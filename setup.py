# Third-Party Libraries
from Cython.Build import cythonize
import numpy
import setuptools


metadata = dict(
    name="bitstream",
    version="3.1b1",
    description="Binary Data for Humans",
    long_description=open("README.md", "rt", encoding="utf-8").read(),
    long_description_content_type="text/markdown",
    url="https://github.com/boisgera/bitstream",
    author="Sébastien Boisgérault",
    author_email="Sebastien.Boisgerault@mines-paristech.fr",
    license="MIT License",
    classifiers=[
        "Development Status :: 5 - Production/Stable",
        "License :: OSI Approved :: MIT License",
        "Operating System :: OS Independent",
        "Programming Language :: Python :: 3",
        "Programming Language :: Cython",
    ],
)


if __name__ == "__main__":
    extensions = cythonize("src/bitstream.pyx", include_path=[numpy.get_include()])
    extensions[0].include_dirs = [numpy.get_include()]

    contents = {
        "packages": setuptools.find_packages(),
        "install_requires": ["numpy"],
        "ext_modules": extensions,
        "zip_safe": False,
    }

    data = {"package_data": {"bitstream": ["__init__.pxd"]}}

    requirements = {"install_requires": ["setuptools"]}

    kwargs = {}
    kwargs.update(metadata)
    kwargs.update(contents)
    kwargs.update(data)
    setuptools.setup(**kwargs)
