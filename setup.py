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

# Third-Party Libraries
import setuptools


metadata = dict(
  name = "bitstream",
  version = "1.0.0-alpha.8",
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

setuptools.Distribution.global_options.extend([
    ("cython", "c", "compile Cython files"),
    ("rest"  , "r", "generate reST documentation")
])


CYTHON = None
REST = None

if os.path.isfile("setup.cfg"):
    parser = ConfigParser.ConfigParser()
    parser.read("setup.cfg")
    try:
        CYTHON = parser.getboolean("global", "cython")
    except ConfigParser.NoOptionError:
        pass
    try:
        REST = parser.getboolean("global", "rest")
    except ConfigParser.NoOptionError:
        pass

def require(module, version=None):
    try:
        _module = importlib.import_module(module)
    except:
        error = "The module {0!r} is not available."
        raise ImportError(error.format(module))
    if version is not None:
        Version = distutils.version.LooseVersion
        if not Version(_module.__version__) >= Version(version):
            error = "The version of {0!r} should be at least {1}."
            raise ImportError(error.format(module, version))

def make_extension():
    if CYTHON:
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

if __name__ == "__main__":

    requirements = dict(
        install_requires = open("requirements.txt").read().splitlines()
    )

    if "-c" in sys.argv:
        sys.argv.remove("-c")
        CYTHON = True
    if "--cython" in sys.argv:
        sys.argv.remove("--cython")
        CYTHON = True

    contents = dict(
      ext_modules = make_extension()
    )

    if "-r" in sys.argv:
        sys.argv.remove("-r")
        REST = True
    if "--rest" in sys.argv:
        sys.argv.remove("--rest")
        REST = True

    if REST:
        make_rest()
    metadata["long_description"] = open("manual.rst").read()

    kwargs = {}
    kwargs.update(metadata)
    kwargs.update(requirements)
    kwargs.update(contents)
    kwargs.update(commands)
    setuptools.setup(**kwargs)

