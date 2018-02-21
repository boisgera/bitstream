

Built-in Types
================================================================================

Bitstream reads and writes work out-of-the-box for many Python data types.
It is also tightly integrated with [NumPy](http://www.numpy.org/),
since this is the library of choice to deals with arrays of numeric data.

    >>> from bitstream import BitStream
    >>> from numpy import *


Bools
--------------------------------------------------------------------------------

Write single bits to a bitstream with the arguments `True` and `False`:

    >>> stream = BitStream()
    >>> stream.write(False, bool)
    >>> stream.write(True , bool)
    >>> stream
    01

Read them back in the same order with

    >>> stream.read(bool)
    False
    >>> stream.read(bool)
    True
    >>> stream
    <BLANKLINE>

Write multiple bits at once with lists of bools:

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

Alternatively, specify the data type `bool` as a a keyword argument:

    >>> stream = BitStream()
    >>> stream.write(False, type=bool)
    >>> stream.write(True , type=bool)
    >>> stream
    01

For single bools or lists of bools, this type information is optional:

    >>> stream = BitStream()
    >>> stream.write(False)
    >>> stream.write(True)
    >>> stream.write([])
    >>> stream.write([False])
    >>> stream.write([True])
    >>> stream.write([False, True])
    >>> stream
    010101

To read one boolean from a stream, do

    >>> stream.read(bool)
    False
    >>> stream
    10101

and to read several booleans, use the second method argument

    >>> stream.read(bool, 2)
    [True, False]
    >>> stream
    101

Since the booleans are returned in a list when the second argument 
differs from the default value (which is `None`), 
`stream.read(bool, 1)` is not same as `stream.read(bool)`:

    >>> copy = stream.copy()
    >>> stream.read(bool, 1)
    [True]
    >>> copy.read(bool)
    True

-----

Numpy `bool_` scalars or one-dimensional arrays can be used instead:

    >>> bool_
    <type 'numpy.bool_'>
    >>> stream = BitStream()
    >>> stream.write(bool_(False)  , bool)
    >>> stream.write(bool_(True)   , bool)
    >>> stream
    01

    >>> stream = BitStream()
    >>> empty = array([], dtype=bool)
    >>> stream.write(empty, bool)
    >>> stream
    <BLANKLINE>
    >>> stream.write(array([False]), bool)
    >>> stream.write(array([True]) , bool)
    >>> stream.write(array([False, True]), bool)
    >>> stream
    0101

For such data, the type information is also optional:

    >>> stream = BitStream()
    >>> stream.write(bool_(False))
    >>> stream.write(bool_(True))
    >>> stream.write(array([], dtype=bool))
    >>> stream.write(array([False]))
    >>> stream.write(array([True]))
    >>> stream.write(array([False, True]))
    >>> stream
    010101

Actually, many more types can be used as booleans 
when the type information is explicit.
For example, Python and Numpy numeric types are valid arguments: 
zero is considered false and nonzero numbers are considered true.

    >>> stream = BitStream()
    >>> stream.write(0.0, bool)
    >>> stream.write(1.0, bool)
    >>> stream.write(pi , bool)
    >>> stream.write(float64(0.0), bool)
    >>> stream.write(float64(1.0), bool)
    >>> stream.write(float64(pi) , bool)
    >>> stream
    011011

Strings are also valid arguments, with a boolean value of `True` unless
they are empty.
One-dimensional lists and numpy arrays are considered holders of 
multiple data, each of which is converted to bool.

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

Any other sequence (strings, tuples, lists nested in lists, etc.) 
is considered as a single datum.

    >>> stream = BitStream()
    >>> stream.write(    (), bool)
    >>> stream.write(  (0,), bool)
    >>> stream.write((0, 0), bool)
    >>> stream
    011

    >>> stream = BitStream()
    >>> stream.write([[], [0], [0, 0]], bool)
    >>> stream
    011

More generally, arbitrary custom "bool-like" instances, 
which have a `__nonzero__` method to handle the conversion 
to boolean, can also be used:

    >>> class BoolLike(object):
    ...     def __init__(self, value):
    ...         self.value = bool(value)
    ...     def __nonzero__(self):
    ...         return self.value
    >>> false = BoolLike(False)
    >>> true = BoolLike(True)

    >>> stream = BitStream()
    >>> stream.write(false, bool)
    >>> stream.write(true, bool)
    >>> stream.write([false, true], bool)
    >>> stream
    0101


BitStreams
--------------------------------------------------------------------------------

A lists of bool is not the most efficient way to represent a binary stream.
The best type is ... an instance of `BitStream` of course! 

Consider the stream

    >>> stream = BitStream()
    >>> stream.write(8 * [True], bool)
    >>> stream
    11111111

To read 2 bits out of `stream` as a bitstream, use

    >>> stream.read(BitStream, 2)
    11

Since this is a common use case, the `BitStream` type is assumed by default:

    >>> new_stream = stream.read(n=2)
    >>> type(new_stream) is BitStream
    True
    >>> new_stream
    11

The simpler code below also works:

    >>> new_stream = stream.read(2)
    >>> type(new_stream) is BitStream
    True
    >>> new_stream
    11

When the number of items to read is also specified (`n=None`),
the read empties the stream:

    >>> stream.read()
    11
    >>> stream
    <BLANKLINE>


Strings
--------------------------------------------------------------------------------

In Python 2.7, strings are the structure of choice to represent 
bytes in memory.
Their type is `str` (or equivalently `bytes` which is an alias).
Fortunately, it's straightforward to convert strings to 
bitstreams: create a stream from the string `"ABCD"` with

    >>> stream = BitStream("ABCD")

To be totally explicit, the code above is equivalent to:

    >>> stream = BitStream()
    >>> stream.write("ABCDE", bytes)

Now, the content of the stream is

    >>> stream
    0100000101000010010000110100010001000101

It is the binary representation
of the ASCII codes of the string characters,
as unsigned 8-bit integers
(see [Integers](#integers) for more details):

    >>> char_codes = [ord(char) for char in "ABCDE"]
    >>> char_codes
    [65, 66, 67, 68, 69]
    >>> stream == BitStream(char_codes, uint8)
    True

There is no "single character" type in Python: 
characters are represented as bytes of length 1.
To read one or several characters from a bitstream, 
use the `read` method with the `bytes` type:

    >>> stream.read(bytes, 1)
    'A'
    >>> stream.read(bytes, 2)
    'BC'

Without an explicit number of characters, the bitstream is emptied

    >>> stream.read(bytes)
    'DE'

but that works only if the bitstream contains a multiple of 8 bits.

    >>> stream = BitStream(42 * [True])
    >>> stream.read(bytes) # doctest: +ELLIPSIS
    Traceback (most recent call last):
    ...
    ReadError: ...

To accept up to seven trailing bits instead, use the more explicit code:

    >>> stream = BitStream(42 * [True])
    >>> n = len(stream) // 8
    >>> n
    5
    >>> stream.read(bytes, n)
    '\xff\xff\xff\xff\xff'
    >>> stream
    11


Integers
--------------------------------------------------------------------------------

First, let's clear something out: 
since Python integers can be of arbitrary size 
and there is not a unique convenient and commonly accepted
representation for such integers[^1],
you cannot create a bitstream from Python integers by default.

    >>> BitStream(1)
    Traceback (most recent call last):
    ...
    TypeError: unsupported type 'int'.

    >>> BitStream(2**100)
    Traceback (most recent call last):
    ...
    TypeError: unsupported type 'long'.

    >>> BitStream("A").read(int)
    Traceback (most recent call last):
    ...
    TypeError: unsupported type 'int'.

[^1]: 
    Why not simply use the binary decomposition of integers? 
    For example, since

        >>> 13 == 1*2**3 + 1*2**2 + 0*2**1 + 1*2**0
        True

    you may be tempted to not represent `13` as 

        >>> BitStream([True, True, False, True])
        1101

    But this scheme is ambiguous if we consider 
    sequences of integers: `1101` could represent the integer
    `13` but also `[1,5]` or `[3,1]` or `[3,0,1]`, etc.

    




You need to specify somehow an integer type that determines 
what binary representation should be used. For example,
to represent `1` as an unsigned 8bit integer:

    >>> BitStream(1, uint8)
    00000001
    >>> BitStream(uint8(1))
    00000001

For integer sequences, there are even more ways 
to specify the integer type:

    >>> BitStream([1,2,3], uint8)
    000000010000001000000011
    >>> BitStream([uint8(1), uint8(2), uint8(3)])
    000000010000001000000011
    >>> BitStream(array([1, 2, 3], dtype=uint8))
    000000010000001000000011
    
Bitstream supports six integer types from numpy:

  - unsigned integers: `uint8`, `uint16`, `uint32`

  - signed integers: `int8`, `int16`, `int32`

The representation of unsigned integers is based on their 
decomposition as powers of 2. For example, since

     >>> 13 ==  1*2**3 + 1*2**2 + 0*2**1 + 1*2**0
     True

we have

     >>> BitStream(13, uint8)
     00001101

In this scheme, only unsigned integers in the range 0-255 can be represented 
as 8bit integers. 
Out-of-bounds integers are accepted, 
but mapped to the correct range by a modulo `2**8` operation. 
Numpy follows this convention

     >>> 500 % 2**8
     244
     >>> uint8(500)
     244

and so does bitstream

     >>> BitStream(500, uint8)
     11110100
     >>> BitStream(244, uint8)
     11110100
     >>> BitStream(500, uint8).read(uint8)
     244

The representation of 16bit and 32bit unsigned integers 
follows the same approach

    >>> BitStream(2**10, uint16)
    0000010000000000
    >>> BitStream(uint16(2**10))
    0000010000000000

For the readers that know about this, we use the [big-endian](https://en.wikipedia.org/wiki/Endianness) representation by default for multi-byte
integers. If you want to use the little-endian convention instead,
NumPy provides the method `newbyteorder` for this:

    >>> BitStream(uint16(2**10).newbyteorder())
    0000000000000100

Finally, for signed integers, we use the [two's complement](https://en.wikipedia.org/wiki/Signed_number_representations) representation

    >>> BitStream(0, int8)
    00000000
    >>> BitStream(1, int8)
    00000001
    >>> BitStream(-1, int8)
    11111111


Floating-Point Numbers
--------------------------------------------------------------------------------

Bitstream supports natively the IEE754 double-precision floating-point numbers,
which have a well-defined binary representation (see e.g. [What every computer scientist should know about binary arithmetic](https://orion.math.iastate.edu/alex/502/doc/p5-goldberg.pdf)).

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

Python built-in `float` type and NumPy `float64` types may be used interchangeably:

    >>> BitStream(1.0) == BitStream(1.0, float) == BitStream(1.0, float64)
    True

Scalar, lists and arrays of floats are supported:

    >>> BitStream(1.0) == BitStream([1.0]) == BitStream(ones(1))
    True

The byte order is big endian:

    >>> import struct
    >>> PI_BE = struct.pack(">d", pi)
    >>> PI_BE
    '@\t!\xfbTD-\x18'
    >>> BitStream(pi) == BitStream(PI_BE)
    True

The NumPy `newbyteorder` method should be used beforeand
(on a `float64` or an array of floats) 
to get a little-endian representation instead.




