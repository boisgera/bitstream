#!/usr/bin/env python
"""
Bitstream Specification
"""

# Python 2.7 Standard Library
import doctest

# Third-Party and Local Libraries
from numpy import *
from bitstream import *

# TODO: transform this into a .txt (markdown). Probably a good idea.

def test_basic():
    """
Quick overview of `bitstream` features:    
    
    >>> stream = BitStream()
    >>> stream
    <BLANKLINE>
    >>> stream.write(True, bool)
    >>> stream
    1
    >>> stream.write(False, bool)
    >>> stream
    10
    >>> stream.write(-128, int8)
    >>> stream
    1010000000
    >>> stream.write("AB", str)
    >>> stream
    10100000000100000101000010
    >>> stream.read(bool, 2)
    [True, False]
    >>> stream
    100000000100000101000010
    >>> stream.read(int8, 1)
    array([-128], dtype=int8)
    >>> stream
    0100000101000010
    >>> stream.read(str, 2)
    'AB'
    >>> stream
    <BLANKLINE>
    """

def test_bool():
    """
Bool Reader and Writer.

To write single bits into a bitstream, use the arguments `True` and `False`:

    >>> stream = BitStream()
    >>> stream.write(False, bool)
    >>> stream.write(True , bool)
    >>> stream
    01

Lists of booleans may be used too write multiple bits at once:

    >>> stream = BitStream()
    >>> stream.write([], bool)
    >>> stream
    <BLANKLINE>
    >>> stream.write([False], bool)
    >>> stream.write([True] , bool)
    >>> stream
    01
    >>> stream.write([False, True], bool)
    >>> stream
    0101

The second argument to the `write` method is the type information: the
first argument is written into the stream as a (sequence of) bool(s).
It can by specified with the keyword argument `type`:

    >>> stream = BitStream()
    >>> stream.write(False, type=bool)
    >>> stream.write(True , type=bool)
    >>> stream
    01

For single bools or lists of bools, the type information is optional:

    >>> stream = BitStream()
    >>> stream.write(False)
    >>> stream.write(True)
    >>> stream.write([])
    >>> stream.write([False])
    >>> stream.write([True])
    >>> stream.write([False, True])
    >>> stream
    010101

Numpy `bool_` scalars or 1-dim. arrays can be used instead:

    >>> stream = BitStream()
    >>> stream.write(bool_(False)  , bool)
    >>> stream.write(bool_(True)   , bool)
    >>> stream.write(array([False]), bool)
    >>> stream.write(array([True]) , bool)
    >>> stream.write(array([False, True]), bool)
    >>> stream
    010101

For such data, the type information is also optional:

    >>> stream = BitStream()
    >>> stream.write(bool_(False))
    >>> stream.write(bool_(True))
    >>> stream.write(array([False]))
    >>> stream.write(array([True]))
    >>> stream.write(array([False, True]))
    >>> stream
    010101

Python and Numpy numeric types are also valid arguments: 
zero is considered false and nonzero numbers are considered true.

    >>> stream = BitStream()
    >>> stream.write(   -2, bool)
    >>> stream.write(   -1, bool)
    >>> stream.write(    0, bool)
    >>> stream.write(    1, bool)
    >>> stream.write(    2, bool)
    >>> stream.write( 2**8, bool)
    >>> stream.write(2**32, bool)
    >>> stream
    1101111

    >>> stream = BitStream()
    >>> stream.write( uint8(0), bool)
    >>> stream.write( uint8(1), bool)
    >>> stream.write( uint8(2), bool)
    >>> stream.write( int8(-1), bool)
    >>> stream.write( int8( 0), bool)
    >>> stream.write( int8(+1), bool)
    >>> stream.write(uint16(0), bool)
    >>> stream.write(uint16(1), bool)
    >>> stream.write(uint16(2), bool)
    >>> stream.write(int16(-1), bool)
    >>> stream.write(int16( 0), bool)
    >>> stream.write(int16(+1), bool)
    >>> stream
    011101011101

    >>> stream = BitStream()
    >>> stream.write(0.0, bool)
    >>> stream.write(1.0, bool)
    >>> stream.write( pi, bool)
    >>> stream.write(float64(0.0), bool)
    >>> stream.write(float64(1.0), bool)
    >>> stream.write(float64( pi), bool)
    >>> stream
    011011

# TODO: arrays of numeric type (non-bools), written as bools

Actually, any single data written as a bool, is conceptually cast into a bool 
first, with the semantics of the `bool` constructor.
Lists and 1-dim. numpy arrays arguments are considered holders of multiple 
data, each of which is converted to bool.
Any other sequence type (strings, tuples, etc.) is considered single data.

    >>> bool("")
    False
    >>> bool(" ")
    True
    >>> bool("A")
    True
    >>> bool("AAA")
    True

    >>> stream = BitStream()
    >>> stream.write("", bool)
    >>> stream.write(" ", bool)
    >>> stream.write("A", bool)
    >>> stream.write("AAA", bool)
    >>> stream
    0111
    >>> stream = BitStream()
    >>> stream.write(["", " " , "A", "AAA"], bool)
    >>> stream
    0111
    >>> stream = BitStream()
    >>> stream.write(array(["", " " , "A", "AAA"]), bool)
    >>> stream
    0111

    >>> stream = BitStream()
    >>> stream.write(    (), bool)
    >>> stream.write(  (0,), bool)
    >>> stream.write((0, 0), bool)
    011

    >>> stream = BitStream()
    >>> stream.write([[], [0], [0, 0]], bool)
    >>> stream
    011
    >>> stream.write(array([[0, 1], [2, 3]]), bool)
    >>> stream
    11

    >>> class BoolLike(object):
    ...     def __init__(self, value):
    ...         self.value = bool(value)
    ...     def __nonzero__(self):
    ...         return self.value
    >>> stream = BitStream()
    >>> stream.write(BoolLike(False), bool)
    >>> stream.write(BoolLike(True), bool)
    >>> stream.write([BoolLike(False), BoolLike(True)], bool)
    >>> stream
    0101


TODO: 

  - direct call to `write_bool`
  - reader tests

    """

def test_float64():
    """
Double Reader and Writer.

    >>> stream = BitStream()
    >>> stream.write(0.0)
    >>> stream.write([1.0, 2.0, 3.0])
    >>> stream.write(arange(4.0, 10.0))
    >>> len(stream)
    640
    >>> output = stream.read(float, 10)
    >>> type(output)
    <type 'numpy.ndarray'>
    >>> all(output == arange(10.0))
    True

    >>> BitStream(1.0) == BitStream(1.0, float) == BitStream(1.0, float64)
    True
    >>> BitStream(1.0) == BitStream([1.0]) == BitStream(ones(1))
    True

The byte order is big endian:
    
    >>> BitStream(struct.pack(">d", pi)) == BitStream(pi)
    True
"""

if __name__ == "__main__":
    doctest.testmod()

