# Bitstream -- Binary Data for Humans

**TODO:** Python 2 badge

[![Build Status](https://travis-ci.org/boisgera/bitstream.svg?branch=master)](https://travis-ci.org/boisgera/bitstream)

**TODO: one-liner**

Bitstream is a Python library to read and write binary data.

Why Bitstream?
--------------------------------------------------------------------------------

Motivation, set of features


Quickstart
--------------------------------------------------------------------------------

Bitstream supports Python 2.7.
Make sure that the [pip] package installer is available 
for this version of the interpreter

    $ pip --version
    pip 9.0.1 from /usr/local/lib/python2.7/dist-packages (python 2.7)

and install bitstream

    $ pip install bitstream

[pip]: https://packaging.python.org/tutorials/installing-packages/#install-pip-setuptools-and-wheel

    >>> from bitstream import BitStream
    >>> BitStream("Hello!")
    010010000110010101101100011011000110111100100001

Examples
--------------------------------------------------------------------------------

    >>> from bitstream import BitStream
    >>> BitStream("Hello!")
    010010000110010101101100011011000110111100100001

Documentation
--------------------------------------------------------------------------------

Contribute / Developers
--------------------------------------------------------------------------------

Link to contributors

License
--------------------------------------------------------------------------------

Bitstream is open source software released under the [MIT license](LICENSE.txt).

Copyright (c) 2012-2017 Sébastien Boisgérault


