#!/usr/bin/env python
# coding: utf-8

# Python 2.7 Standard Library
from distutils.version import StrictVersion as Version

# Third-Party Libraries
import setuptools
from Cython.Build import cythonize


def require_numpy(version=None):
    try:
        import numpy
    except:
        error = "The NumPy package is not available."
        raise ImportError(error)
    if version:
        if not Version(numpy.__version__) >= Version(version):
            error = "The version of NumPy should be at least {0}."
            raise ImportError(error.format(version))

metadata = dict(
  name = "bitstream",
  version = "0.0.0.dev",
  description = "Binary data structure with a stream interface",
  url = "https://github.com/boisgera/bitstream",
  author = u"Sébastien Boisgérault",
  author_email = "Sebastien.Boisgerault@mines-paristech.fr",
  license = "MIT License",
)

contents = dict(
  ext_modules = cythonize("bitstream.pyx")
)


if __name__ == "__main__":
    require_numpy("1.6.1")
    kwargs = {}
    kwargs.update(metadata)
    kwargs.update(contents)
    setuptools.setup(**kwargs)

