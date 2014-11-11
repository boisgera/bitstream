#!/usr/bin/env python
# coding: utf-8

# Python 2.7 Standard Library
import ConfigParser
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
import setuptools
<<<<<<< HEAD
import numpy

# TODO: to build the library, numpy headers (arrayobject.h for example)
#       are needed, handle that. When setuptools is "playing" with bitstream,
#       the headers are not installed (yet ?). Have a look at
#       <http://mail.scipy.org/pipermail/numpy-discussion/2010-April/049782.html>
#       Get rid of the install_require approach, check it manually (numpy,
#       version >= 1.8 and headers location) and document why.


import pkg_resources

# Numpy
try:
    requirement = "numpy"
    pkg_resources.require(requirement)
    import numpy
except pkg_resources.DistributionNotFound:
    error = "{0!r} not available".format(requirement)
    raise ImportError(error)

#
# Metadata
# ------------------------------------------------------------------------------
#
metadata = dict(
  name = "bitstream",
  version = "2.1.0-alpha",
  description = "A Binary Data Type with a Stream Interface",
  url = "https://github.com/boisgera/bitstream",
  author = u"Sébastien Boisgérault",
  author_email = "Sebastien.Boisgerault@mines-paristech.fr",
  license = "MIT License",
  classifiers = [
    "Development Status :: 3 - Alpha",
    "License :: OSI Approved :: MIT License",
    "Operating System :: POSIX :: Linux",
    "Programming Language :: Python :: 2.7",
    "Programming Language :: Cython",
    ]
)

#
# CYTHON and REST options management (from setup.cfg)
# ------------------------------------------------------------------------------
#
CYTHON = None
REST = None

setuptools.Distribution.global_options.extend([
    ("cython", None, "compile Cython files"),
    ("rest"  , None, "generate reST documentation")
])
>>>>>>> snapshot

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
        parser = ConfigParser.ConfigParser()
        parser.read("setup.cfg")
        try:
            CYTHON = trueish(parser.get("global", "cython"))
        except (ConfigParser.NoOptionError, ConfigParser.NoSectionError):
            pass
        try:
            REST = trueish(parser.get("global", "rest"))
        except (ConfigParser.NoOptionError, ConfigParser.NoSectionError):
            pass

import_CYTHON_REST_from_setup_cfg()

#
# Custom developer commands
# ------------------------------------------------------------------------------
#
def make_extension():
    if CYTHON:
        pkg_resources.require("Cython")
        import Cython
        from Cython.Build import cythonize
        return cythonize("bitstream.pyx", include_dirs=[numpy.get_include()])
    else:
        if os.path.exists("bitstream.c"):
            return [setuptools.Extension("bitstream", 
                                         sources=["bitstream.c"],
                                         include_dirs=[numpy.get_include()])]
        else:
            error = "file not found: 'bitstream.c'"
            raise IOError(error)

def make_rest():
    error = os.system("pandoc -o manual.rst manual.txt")
    if error:
        raise OSError(error, "cannot generate ReST documentation")

def make_pdf():
    "Generate a PDF documentation"
    title  = metadata["name"].capitalize() + " " + metadata["version"]
    author = metadata["author"].encode("utf-8")
    date   = datetime.date.today().strftime("%d %B %Y")
    header = "%{0}\n%{1}\n%{2}\n\n".format(title, author, date)
    file = tempfile.NamedTemporaryFile()
    file.write(header)
    file.write(open("manual.txt").read())
    file.flush()
    error = os.system("pandoc -o manual.pdf {0}".format(file.name))
    file.close()
    if error:
        raise OSError(error, "cannot generate PDF documentation")

def command(function):
     contents = dict(
       description = function.__doc__, 
       user_options = [],
       initialize_options = lambda self: None,
       finalize_options = lambda self: None,
       run = lambda self: function()
     )
     return type(
       function.__name__.capitalize(), 
       (setuptools.Command, object), 
       contents
     )

commands = dict(
    cmdclass = dict(
        pdf = command(make_pdf)
    )
)

#
# Setup
# ------------------------------------------------------------------------------
#
if __name__ == "__main__":

    # TODO: transform bitstream into a package, include bitstream.pxd as
    # package data, provide some API to get the path of the pxd file
    # (such as get_pxd or get_include ? find a project that already does that, 
    # such as lxml). Then, in the cython packages that depend on the pxd files,
    # install bitstream as a setup dependency, query the path of the pxd file,
    # then specify the path with cythonize (i hope that the API allows it).
    # UPDATE: go for get_include, lxml also uses this pattern (but returns
    # a list, not a string like numpy)

    # CYTHON and REST options management (from command-line)
    if "--cython" in sys.argv:
        sys.argv.remove("--cython")
        CYTHON = True
    if "--rest" in sys.argv:
        sys.argv.remove("--rest")
        REST = True

    # Execution of custom commands
    contents = dict(
      ext_modules = make_extension()
    )

    if REST:
        make_rest()
    metadata["long_description"] = open("manual.rst").read()

    # Assembly of setup arguments
    kwargs = {}
    kwargs.update(metadata)
    kwargs.update(contents)
    kwargs.update(commands)

    # Setup    
    setuptools.setup(**kwargs)

