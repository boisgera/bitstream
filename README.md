# Bitstream -- Binary Data for Humans

[![Python 2.7](https://img.shields.io/badge/python-2.7-blue.svg)](https://www.python.org/download/releases/2.7/)
[![PyPI version](https://badge.fury.io/py/bitstream.svg)](https://badge.fury.io/py/bitstream)
[![Build Status](https://travis-ci.org/boisgera/bitstream.svg?branch=master)](https://travis-ci.org/boisgera/bitstream)


**TODO: one-liner**

Bitstream is a Python library to read and write binary data.

Why Bitstream?
--------------------------------------------------------------------------------

Motivation, set of features


Quickstart
--------------------------------------------------------------------------------

Make sure that Python 2.7 is installed and that pip, NumPy and a C compiler 
are available, then install bitstream with

    $ pip install bitstream

[pip]: https://packaging.python.org/tutorials/installing-packages/#install-pip-setuptools-and-wheel

For more details, refer to [the documentation][install].

[install]: http://boisgera.github.io/bitstream/installation/

Examples
--------------------------------------------------------------------------------

First, the mandatory "Hello World!" example:

    >>> from bitstream import BitStream
    >>> BitStream("Hello World!")
    010010000110010101101100011011000110111100100000010101110110111101110010011011000110010000100001

The basic API is made of three methods only:

| Action        | Code                          |
|---------------|-------------------------------|
| Create stream | `stream = BitStream()`        |
| Write data    | `stream.write(data, type)`    |
| Read data     | `data = stream.read(type, n)` |

For example:

    >>> stream = BitStream()      # <empty>
    >>> stream.write(True, bool)  # 1
    >>> stream.write(False, bool) # 10
    >>> stream.write(-128, int8)  # 1010000000
    >>> stream.write("AB", str)   # 10100000000100000101000010
    >>> stream.read(bool, 2)      # 100000000100000101000010
    [True, False]
    >>> stream.read(int8, 1)      # 0100000101000010
    array([-128], dtype=int8)
    >>> stream.read(str, 2)       # <empty>
    "AB"

Refer to [the documentation](http://boisgera.github.io/bitstream/) for more
information.


Contribute / Developers
--------------------------------------------------------------------------------

Link to contributors

License
--------------------------------------------------------------------------------

Bitstream is open source software released under the [MIT license](LICENSE.txt).

Copyright (c) 2012-2017 Sébastien Boisgérault


