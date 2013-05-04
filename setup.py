#!/usr/bin/env python
# coding: utf-8

# Python 2.7 Standard Library
from distutils.version import LooseVersion as Version
import importlib
import os.path
import sys

# Third-Party Libraries
import setuptools


WITH_CYTHON = True

def require(module, version=None):
    try:
        _module = importlib.import_module(module)
    except:
        error = "The module {0!r} is not available."
        raise ImportError(error.format(module))
    if version is not None:
        if not Version(_module.__version__) >= Version(version):
            error = "The version of {0!r} should be at least {1}."
            raise ImportError(error.format(module, version))

def make_extension(with_cython=None):
    if with_cython is None:
        with_cython = WITH_CYTHON
    if with_cython:
        require("Cython", "0.15.1")
        import Cython
        from Cython.Build import cythonize
        print cythonize("bitstream.pyx")
        return cythonize("bitstream.pyx")
    else:
        if os.path.exists("bitstream.c"):
            return [setuptools.Extension("bitstream", sources=["bitstream.c"])]
        else:
            error = "file not found: 'bitstream.c'"
            raise IOError(error)

metadata = dict(
  name = "bitstream",
  version = "1.0.0-alpha.1",
  description = "Binary data structure with a stream interface",
  url = "https://github.com/boisgera/bitstream",
  author = u"Sébastien Boisgérault",
  author_email = "Sebastien.Boisgerault@mines-paristech.fr",
  license = "MIT License",
)


if __name__ == "__main__":

    require("numpy", "1.6.1")

    try:
        print sys.argv
        sys.argv.remove("--without-cython")
        WITH_CYTHON = False
    except ValueError:
        pass
    contents = dict(
      ext_modules = make_extension()
    )

    kwargs = {}
    kwargs.update(metadata)
    kwargs.update(contents)
    setuptools.setup(**kwargs)

