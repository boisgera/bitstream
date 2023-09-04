#!/usr/bin/env python
# coding: utf-8

# Python Standard Library
import configparser
import datetime
import distutils.version
import importlib
import os
import os.path
import sys
import tempfile

# Pip Package Manager
try:
    import pip
except ImportError:
    error = "pip is not installed, refer to <{url}> for instructions."
    raise ImportError(error.format(url="http://pip.readthedocs.org"))
import pkg_resources
import setuptools

# NumPy 
try:
    pkg_resources.require("numpy")
    import numpy
except pkg_resources.DistributionNotFound:
    error  = "numpy not available. Try the command 'pip install -m numpy' "
    error += "or use a pre-built package for your operating system."
    raise ImportError(error)


# Metadata
# ------------------------------------------------------------------------------
metadata = dict(
  name = "bitstream",
  version = "3.0",
  description = "Binary Data for Humans",
  url = "https://github.com/boisgera/bitstream",
  author = u"Sébastien Boisgérault",
  author_email = "Sebastien.Boisgerault@mines-paristech.fr",
  license = "MIT License",
  classifiers = [
    "Development Status :: 5 - Production/Stable",
    "License :: OSI Approved :: MIT License",
    "Operating System :: OS Independent",
    "Programming Language :: Python :: 3",
    "Programming Language :: Cython",
    ]
)


# CYTHON and REST options management (from setup.cfg)
# ------------------------------------------------------------------------------
CYTHON = None
REST = None

setuptools.Distribution.global_options.extend([
    ("cython", None, "compile Cython files"),
    ("rest"  , None, "generate reST documentation")
])

def trueish(value):
    if not isinstance(value, str):
        return bool(value)
    else:
        value = value.lower()
        if value in ("y", "yes", "t", "true", "on", "1"):
            return True
        elif value in ("", "n", "no", "f", "false", "off", "0"):
            return False
        else:
            raise TypeError("invalid bool value {0!r}, use 'true' or 'false'.")

def import_CYTHON_REST_from_setup_cfg():
    global CYTHON, REST
    if os.path.isfile("setup.cfg"):
        parser = configparser.ConfigParser()
        parser.read("setup.cfg")
        try:
            CYTHON = trueish(parser.get("global", "cython"))
        except (configparser.NoOptionError, configparser.NoSectionError):
            pass
        try:
            REST = trueish(parser.get("global", "rest"))
        except (configparser.NoOptionError, configparser.NoSectionError):
            pass

import_CYTHON_REST_from_setup_cfg()


# Custom developer commands
# ------------------------------------------------------------------------------
def make_extension():
    if CYTHON:
        pkg_resources.require("Cython")
        import Cython
        from Cython.Build import cythonize
        extensions = cythonize("src/bitstream.pyx", 
                               include_path=[numpy.get_include()])
        extensions[0].include_dirs=[numpy.get_include()]
        return extensions
    else:
        if os.path.exists("src/bitstream.c"):
            return [setuptools.Extension("bitstream", 
                                         sources=["src/bitstream.c"],
                                         include_path=[numpy.get_include()])]
        else:
            error  = "C files not found, Cython compilation required: \n"
            error += "execute `python setup.py --cython install`"
            raise IOError(error)

def make_rest():
    "Generate a ReStructuredText README"
    error = os.system("pandoc -o README.rst README.md")
    if error:
        raise OSError(error, "cannot generate ReST documentation")


# Setup
# ------------------------------------------------------------------------------
if __name__ == "__main__":
    # CYTHON and REST options management (from command-line)
    if "--cython" in sys.argv:
        sys.argv.remove("--cython")
        CYTHON = True
    if "--rest" in sys.argv:
        sys.argv.remove("--rest")
        REST = True

    contents = dict(
      packages = setuptools.find_packages(),
      ext_modules = make_extension(),
      zip_safe = False,
    )

    data = dict(
      package_data = {"bitstream": ["__init__.pxd"]}
    )

    requirements = dict(
      install_requires = ["setuptools"]
    )

    if REST:
        make_rest()
    if os.path.isfile("README.rst"):
        try:
            long_description = open("README.rst").read()
        except UnicodeDecodeError:
            long_description = open("README.rst", encoding="utf-8").read()
        
        metadata["long_description"] = long_description

    # Assembly of setup arguments
    kwargs = {}
    kwargs.update(metadata)
    kwargs.update(contents)
    kwargs.update(data)

    # Setup    
    setuptools.setup(**kwargs)

