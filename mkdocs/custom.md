
Custom Writers and Readers
================================================================================

This section explains how to deal with a data type or a binary coding 
that bitstream does not support natively: how to define bitstream 
writer and reader functions and register them so that your custom
types behave like native ones.

    >>> import bitstream
    >>> from bitstream import BitStream

We use the example of representation of unsigned integers 
as binary numbers;
out of the box, bitstream only supports unsigned integers of fixed size 
(refer to [Built-in Types / Integers](../types/#integers) for details).
 

Definition
--------------------------------------------------------------------------------

For every type of data that we want bitstream to support, 
we need to specify at least one writer function that
encodes the data as a bitstream and one reader function
that decodes data out of bitstreams.

The signature of writers is

    def writer(stream, data)

where

 1. `stream` is a `BitStream` instance,

 2. the type of `data` is writer-dependent.

A writer is totally free to specify what is a valid `data`,
but it is sensible to accept:

  - instances of a reference data type (or some of these instances),

  - data that can be safely converted to the reference data type,

  - sequences (lists, arrays, etc.) of the reference type (or assimilated).
 
A writer should raise an exception (`ValueError` or `TypeError`) 
when the data is invalid.

-----

To write unsigned integers as binary numbers for example,
we can consider as valid anything any non-negative integer-like
data (defined as anything that the constructor `int` accepts) 
as well as lists of such data.

    >>> def write_uint(stream, data):
    ...     if isinstance(data, list):
    ...         for integer in data:
    ...             write_uint(stream, integer)
    ...     else:
    ...         integer = int(data)
    ...         if integer < 0:
    ...             error = "negative integers cannot be encoded"
    ...             raise ValueError(error)
    ...         bools = []
    ...         while integer:
    ...             bools.append(integer & 1)
    ...             integer = integer >> 1
    ...         bools.reverse()
    ...         stream.write(bools, bool)

This writer behaves as expected:

    >>> stream = BitStream()
    >>> write_uint(stream, 42)
    >>> stream
    101010
    >>> write_uint(stream, [1, 2, 3])
    >>> stream
    10101011011
    >>> write_uint(stream, -1)
    Traceback (most recent call last):
    ...
    ValueError: negative integers cannot be encoded
    >>> write_uint(stream, {})
    Traceback (most recent call last):
    ...
    TypeError: int() argument must be a string or a number, not 'dict'

-----

The signature of readers is:

    def reader(stream, n=None)

where

  - `stream` is a `BitStream` instance,

  - `n` is a non-negative integer (or `None`).

The call `read(stream, n)` should read `n` data items 
out of `stream` when `n` is an integer. 
However, bitstream does not require a specific type of container 
(list, array, string, etc.), the choice is all yours;
for consistency however, you should pick a type of container
that your writer supports.

The semantics of call `read(stream)` (when `n=None`) is up to you; 
for most of built-in types, it returns a single (unboxed) datum of
the stream but there are sometimes good reasons to decide otherwise
(see for example [strings](../types/#strings)).
The support for this default case is not mandatory.

Actually, readers may support only a subset of the possible values of `n`;
for example they may allow only `n=1` and `n=None`.
If a reader is called with an invalid value of `n`,
a `ValueError` or `TypeError` exception should be raised. 
If instead the `read` fails because there is not enough 
data in the stream or more generally if the binary data
cannot be decoded, a `ReadError` (from `bitstream`) should 
be raised.

-----

When we represent unsigned integers as binary numbers,
while we can write multiple integers in the same stream,
we cannot read unambiguously multiple integers from the 
stream: the code is not *self-delimiting*. 
For example `110` can be split as `1` then `10`
and code for the integers `1` and `2` but also 
as `11` and `0` which represent the integers `3` and `0`.

Thus, we design a reader that reads the whole stream as a single 
integer: we support only the cases `n=1` 
and for convenience the default `n=None` with the same result.

A possible implementation of this reader is:

    >>> def read_uint(stream, n=None):
    ...     if n is not None and not n == 1:
    ...         error = "unsupported argument n = {0!r}".format(n)
    ...         raise ValueError(error)
    ...     else:
    ...         integer = 0
    ...         for _ in range(len(stream)):
    ...             integer = integer << 1
    ...             if stream.read(bool):
    ...                 integer += 1
    ...     return integer

It behaves as expected:

    >>> stream = BitStream()
    >>> write_uint(stream, 42)
    >>> read_uint(stream)
    42
    >>> write_uint(stream, [1, 2, 3]) 
    >>> read_uint(stream)
    27
    >>> len(stream)
    0
    >>> write_uint(stream, 42)
    >>> read_uint(stream, 1)
    42
    >>> write_uint(stream, 42)
    >>> read_uint(stream, 2)
    Traceback (most recent call last):
    ...
    ValueError: unsupported argument n = 2


Registration
--------------------------------------------------------------------------------

To fully integrate unsigned integers into bitstream, 
you need to associate a unique type identifier to 
the reader and/or writer, 
This type identifier is usually a type;
a user-defined type with an empty 
definition will do:

    >>> class uint(object):
    ...     pass

Once the type `uint` has been associated to the unsigned integer writer

    >>> bitstream.register(uint, writer=write_uint)

we can use the `write` method of `BitStream` to encode unsigned integers

    >>> stream = BitStream()
    >>> stream.write(42, uint)
    >>> stream
    101010

    >>> stream = BitStream()
    >>> stream.write([2, 2, 2], uint)
    >>> stream
    101010

and also the shorter former using the `BitStream` constructor

    >>> BitStream(42, uint)
    101010
    >>> BitStream([2, 2, 2], uint)
    101010

Once the reader is registered

    >>> bitstream.register(uint, reader=read_uint)

we can also use the `read` method of `BitStream`:

    >>> BitStream(42, uint).read(uint)
    42

Here, the `uint` type was merely an identifier for our reader and writer,
but "real" types can be used too. If you write some data whose type is
the type identifier of a writer, you don't need to specify explicitly the
type identifier in writes.

For example, if we also associate our writer with Python integers:

    >>> bitstream.register(int, writer=write_uint)
    >>> bitstream.register(long, writer=write_uint)

then every Python integer will be automatically encoded with 
the `write_uint` writer

    >>> BitStream(42)
    101010
    >>> BitStream([2, 2, 2])
    101010


Factories
--------------------------------------------------------------------------------

The coding of arbitrary unsigned integers as binary numbers 
doesn't allow us to represent unambiguously multiple numbers in a stream. However, if there is a known bound on the integers we use, we can
assign a sufficient numbers of bits to each integer, pad the
binary numbers with enough zeros of the left to use the same
number of bits and this code is self-delimiting.

However, to do that, we would have to define and register a new writer 
for every possible number of bits. 
Instead, we may register a single but configurable writer, defined
by a writer factory.

Let's define a type identifier factory `uint` whose instances 
hold a number of bits:

    >>> class uint(object):
    ...     def __init__(self, num_bits):
    ...         self.num_bits = num_bits

Then, we define a writer factory: given an instance of `uint`, 
it returns a stream writer:

    >>> def write_uint_factory(instance):
    ...     num_bits = instance.num_bits
    ...     def write_uint(stream, data):
    ...         if isinstance(data, list):
    ...             for integer in data:
    ...                 write_uint(stream, integer)
    ...         else:
    ...             integer = int(data)
    ...             if integer < 0:
    ...                 error = "negative integers cannot be encoded"
    ...                 raise ValueError(error)
    ...             bools = []
    ...             for _ in range(num_bits):
    ...                 bools.append(integer & 1)
    ...                 integer = integer >> 1
    ...             bools.reverse()
    ...             stream.write(bools, bool)
    ...     return write_uint

Finally, we register this writer factory with `bitstream`:

    >>> bitstream.register(uint, writer=write_uint_factory)

To select a writer, we use the appropriate type identifier:

    >>> BitStream(255, uint(8))
    11111111
    >>> BitStream(255, uint(16))
    0000000011111111
    >>> BitStream(42, uint(8))
    00101010
    >>> BitStream(0, uint(16))
    0000000000000000

The definition of a reader factory is similar:

    >>> def read_uint_factory(instance):
    ...     num_bits = instance.num_bits
    ...     def read_uint(stream, n=None):
    ...         if n is None:
    ...             integer = 0
    ...             for _ in range(num_bits):
    ...                 integer = integer << 1
    ...                 if stream.read(bool):
    ...                     integer += 1
    ...             return integer
    ...         else:
    ...             integers = [read_uint(stream) for _ in range(n)]
    ...             return integers
    ...     return read_uint

Once the reader factory is registered

    >>> bitstream.register(uint, reader=read_uint_factory)

we can use the family of type identifiers in reads too:

    >>> stream = BitStream([0, 1, 2, 3, 4], uint(8))
    >>> stream.read(uint(8))
    0
    >>> stream.read(uint(8), 1)
    [1]
    >>> stream.read(uint(8), 3)
    [2, 3, 4]

