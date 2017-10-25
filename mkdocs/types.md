

Built-in Readers and Writers
================================================================================

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
bitstreams: create a stream from the string `"ABC"` with

    >>> stream = BitStream("ABC")

To be totally explicit, the code above is equivalent to:

    >>> stream = BitStream()
    >>> stream.write("ABC", str)

Now, the content of the stream is

    >>> stream
    010000010100001001000011

It is the binary representation
of the ASCII codes of the string characters,
as unsigned 8-bit integers
(see [Integers](#integers) for more details):

    >>> char_codes = [ord(char) for char in "ABC"]
    >>> char_codes
    [65, 66, 67]
    >>> stream == BitStream(char_codes, uint8)
    True

Now as usual, any number of characters

    >>> stream.read(str, 1)
    'A'

Without an explicit number of characters, the bitstream is emptied

    >>> stream.read(str)
    'BC'

but that works only if the remaining number of bits is a multiple of 8.

    >>> stream = BitStream(42 * [True])
    >>> stream.read(str) # doctest: +ELLIPSIS
    Traceback (most recent call last):
    ...
    ReadError: ...

To accept up to seven trailing bits instead, use the more explicit code:

    >>> stream = BitStream(42 * [True])
    >>> n = len(stream) // 8
    >>> n
    5
    >>> stream.read(str, n)
    '\xff\xff\xff\xff\xff'
    >>> stream
    11


Integers
--------------------------------------------------------------------------------

  - start with `uint8`

  - then `int8` and two's complement scheme & reference

  - then talk about endianness (the concept), 
    our default choice (are we really portable? check)
    and how to change it if that's not what you want.

Supported types:

  - `uint8`, `uint16`, `uint32`, 

  - `int8`, `int16`, `int32`,


Floating-Point Numbers
--------------------------------------------------------------------------------

    >>> import struct
    >>> struct.pack(">d", pi)
    '@\t!\xfbTD-\x18'

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






