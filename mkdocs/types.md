

Built-in Readers and Writers
================================================================================

Bools
--------------------------------------------------------------------------------

Write single bits to a bitstream with the arguments `True` and `False`:

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

The second argument to the `write` method -- the type information -- can 
also be specified with the keyword argument `type`:

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

Python and Numpy numeric types are also valid arguments: 
zero is considered false and nonzero numbers are considered true.


**Q:** Use a predicate instead (non-zero) ? and check iff ?

    >>> small_integers = range(0, 64)
    >>> stream = BitStream()
    >>> for integer in small_integers:
    ...     stream.write(integer, bool)
    >>> stream
    0111111111111111111111111111111111111111111111111111111111111111
    >>> stream = BitStream()
    >>> for integer in small_integers:
    ...     stream.write(-integer, bool)
    >>> stream
    0111111111111111111111111111111111111111111111111111111111111111

    >>> large_integers = [2**i for i in range(6, 64)]
    >>> stream = BitStream()
    >>> for integer in large_integers:
    ...     stream.write(integer, bool)
    >>> stream
    1111111111111111111111111111111111111111111111111111111111
    >>> stream = BitStream()
    >>> for integer in large_integers:
    ...     stream.write(-integer, bool)
    >>> stream
    1111111111111111111111111111111111111111111111111111111111

**TODO:** use iinfo(type).min/max

**TODO:** write `sample(type, r)` iterator.

    >>> def irange(start, stop, r=1.0):
    ...     i = 0
    ...     while i < stop:
    ...         yield i
    ...         i = max(i+1, int(i*r))

    >>> unsigned = [uint8, uint16, uint32]
    >>> for integer_type in unsigned:
    ...     _min, _max = iinfo(integer_type).min, iinfo(integer_type).max
    ...     for i in irange(_min, _max + 1, r=1.001):
    ...         integer = integer_type(i)
    ...         if integer and BitStream(integer, bool) != BitStream(True):
    ...             type_name = integer_type.__name__
    ...             print "Failure for {0}({1})".format(type_name, integer)





    >>> stream = BitStream()
    >>> stream.write(0.0, bool)
    >>> stream.write(1.0, bool)
    >>> stream.write(pi , bool)
    >>> stream.write(float64(0.0), bool)
    >>> stream.write(float64(1.0), bool)
    >>> stream.write(float64(pi) , bool)
    >>> stream
    011011

**TODO:** arrays of numeric type (non-bools), written as bools

-----

**TODO:** Mark all following behaviors as undefined ? Probably safer ...

Actually, any single data written as a bool, is conceptually cast into a bool 
first, with the semantics of the `bool` constructor.
List and one-dimensional numpy array arguments are considered holders of 
multiple data, each of which is converted to bool.
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
    >>> stream
    011

    >>> stream = BitStream()
    >>> stream.write([[], [0], [0, 0]], bool)
    >>> stream
    011

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


TODO: 

  - direct call to `write_bool` (import the symbol first)
  - reader tests


Integers
--------------------------------------------------------------------------------

**TODO**


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
