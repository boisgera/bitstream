[![Python 2.7](https://img.shields.io/badge/python-2.7-blue.svg)](https://www.python.org/download/releases/2.7/)
[![PyPI version](https://img.shields.io/pypi/v/bitstream.svg)](https://pypi.python.org/pypi/bitstream/2.0.3)
[![Mkdocs](https://img.shields.io/badge/doc-mkdocs-blue.svg)](http://boisgera.github.io/bitstream)
[![Build Status](https://travis-ci.org/boisgera/bitstream.svg?branch=master)](https://travis-ci.org/boisgera/bitstream)

# Bitstream

A Python library to manage binary data as [bitstreams](https://en.wikipedia.org/wiki/Bitstream).

Overview
--------------------------------------------------------------------------------

Bitstream three main features:

  - It is easy to use since the bitstream abstraction is simple.

  - It works seamlesly at the bit and byte level.

  - It supports Python, NumPy and user-defined types.

See the documentation [Overview](http://boisgera.github.io/bitstream)
section for more details.


Quickstart
--------------------------------------------------------------------------------

Make sure that Python 2.7 is installed and that pip, NumPy and a C compiler 
are available, then install bitstream with

    $ pip install bitstream

[pip]: https://packaging.python.org/tutorials/installing-packages/#install-pip-setuptools-and-wheel

For more details, refer to [the documentation](http://boisgera.github.io/bitstream/installation/).

Examples
--------------------------------------------------------------------------------

First, the mandatory "Hello World!" example:

    >>> from bitstream import BitStream
    >>> BitStream("Hello World!")
    010010000110010101101100011011000110111100100000010101110110111101110010011011000110010000100001

The basic API is made of three methods only:

  - `stream = BitStream()` to create an empty stream.

  - `stream.write(data, type)` to write data `data` of type `type`.

  - `data = stream.read(type, n)` to read `n` items of type `type`.

For example:

    >>> stream = BitStream()      # <empty>
    >>> stream.write(True, bool)  # 1
    >>> stream.write(False, bool) # 10
    >>> from numpy import int8
    >>> stream.write(-128, int8)  # 1010000000
    >>> stream.write("AB", str)   # 10100000000100000101000010
    >>> stream.read(bool, 2)      # 100000000100000101000010
    [True, False]
    >>> stream.read(int8, 1)      # 0100000101000010
    array([-128], dtype=int8)
    >>> stream.read(str, 2)       # <empty>
    "AB"

Refer to the documentation [Overview](http://boisgera.github.io/bitstream/) 
section for more elementary examples.


Contributing
--------------------------------------------------------------------------------

Refer to [Contributing](http://boisgera.github.io/bitstream/contributing) in the
documentation.


License
--------------------------------------------------------------------------------

Bitstream is open source software released under the [MIT license](https://github.com/boisgera/bitstream/blob/master/LICENSE.txt).

Copyright (c) 2012-2017 Sébastien Boisgérault


