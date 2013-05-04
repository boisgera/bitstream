#!/usr/bin/env python
# coding: utf-8

# Python 2.7 Standard Library
from distutils.version import LooseVersion as Version
import importlib
import os
import os.path
import sys

# Third-Party Libraries
import setuptools


metadata = dict(
  name = "bitstream",
  version = "1.0.0-alpha.4",
  description = "Binary Data Structure with a Stream Interface",
  url = "https://github.com/boisgera/bitstream",
  author = u"Sébastien Boisgérault",
  author_email = "Sebastien.Boisgerault@mines-paristech.fr",
  license = "MIT License",
)

WITH_CYTHON = False
WITH_REST = False

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
        return cythonize("bitstream.pyx")
    else:
        if os.path.exists("bitstream.c"):
            return [setuptools.Extension("bitstream", sources=["bitstream.c"])]
        else:
            error = "file not found: 'bitstream.c'"
            raise IOError(error)

def make_rest():
    error = os.system("pandoc -o manual.rst manual.txt > /dev/null")
    if error:
        raise RuntimeError("cannot generate ReST documentation.")


if __name__ == "__main__":

    requirements = dict(
        install_requires = open("requirements.txt").read().splitlines()
    )

    try:
        sys.argv.remove("--with-cython")
        WITH_CYTHON = True
    except ValueError:
        pass
    contents = dict(
      ext_modules = make_extension()
    )

    try:
        sys.argv.remove("--with-rest")
        WITH_REST = True
    except ValueError: 
        pass

    if WITH_REST:
        make_rest()
    metadata["long_description"] = open("manual.rst").read()

    kwargs = {}
    kwargs.update(metadata)
    kwargs.update(requirements)
    kwargs.update(contents)
    setuptools.setup(**kwargs)

