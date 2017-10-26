
Custom Writers and Readers
================================================================================

This section explains what to do if you want bitstream to manage a data type which is not supported natively, 
or if you want to use an alternative encoding for a supported type.

    >>> import bitstream
    >>> from bitstream import BitStream

We use the example of the base-2 numeral representation of unsigned integers.
Bitstream only supports unsigned integers but only of fixed size (8, 16 or 32 bit long) by default (see [the Integers section in Built-in Types](../types/#integers)), but it's rather easy
to write your own writer and reader functions for the general case.
 

Definition
--------------------------------------------------------------------------------

To fully integrate your custom type into bitstream, you will need
to define writer and reader functions. 
The signature of a writer should be

    def writer(stream, data)

where

  - `stream` is a `BitStream` instance,

  - the type of `data` is writer-dependent[^valid].

[^valid]:
    A writer should specify what is a valid `data`.
    Usually, it is: a given data type, maybe the data type
    that can be safely converted to the data type
    and often sequences (lists, arrays, etc.) of the given
    type.

Invalid writer data should raise a `ValueError`, `TypeError` or 
`bitstream.WriteError` exception when the data is invalid.



The signature of a reader should be

    def reader(stream, n=None)

where

  - `stream` is a `BitStream` instance,

  - `n` is a non-negative integer (or `None`).

The semantics of `read(stream, n)` is loosely "read
`n` items out of `stream`" when `n` is an integer
and of `read(stream)`

Readers may support a subset of the possible values of `n`;
for example only `n=1` is allowed, or only `n=None`.

If a reader call does not respect this, 
a `NotImplementedError` or a `ValueError` exception 
should be raised. 
If instead the `read` fails because there is not enough 
data in the stream or more generally if the binary data
is inconsistent with the reader logic, a 
`bitstream.ReadError` should be raised.

Let's define a writer for the binary representation of unsigned integers:

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

We can check that this writer behaves as expected:

    >>> stream = BitStream()
    >>> write_uint(stream, 42)
    >>> stream
    101010
    >>> write_uint(stream, [1, 2, 3])
    >>> stream
    10101011011



In the case of unsigned integers, we decide to:

  - use list to holds integers[^arrays] when `n` is given,

  - by default (`n=None`) return a single integer

A possible implementation of the reader is:

    >>> def read_uint(stream, n=None):
    ...     if n is not None:
    ...         error = "unsupported argument n"
    ...         raise NotImplementedError(error)
    ...     else:
    ...         integer = 0
    ...         for _ in range(len(stream)):
    ...             integer = integer << 1
    ...             if stream.read(bool):
    ...                 integer += 1
    ...     return integer

    >>> stream = BitStream()
    >>> write_uint(stream, 42)
    >>> read_uint(stream)
    42

[^arrays]:
   NumPy arrays would be another option,
   but the only arrays that can hold arbitrary large integers 
   have the `object` data type which provide little
   benefits over lists.


Registration
--------------------------------------------------------------------------------

To fully integrate unsigned integers into bitstream, 
we need to associate a type identifier to reader and writer, 
a process that associates them to a type.
This type identifier is usually a type,
typically a user-defined type 
with an empty definition:

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
but "real" types can be used too. If you write some data whose type has
been associated to a writer, you don't need to specify explicitly the
type information.

For example, if we also associate our writer with Python integers:

    >>> bitstream.register(int, writer=write_uint)
    >>> bitstream.register(long, writer=write_uint)

then every Python integer will be implicitly written to stream with 
the `write_uint` writer

    >>> BitStream(42)
    101010
    >>> BitStream([2, 2, 2])
    101010



Factories
--------------------------------------------------------------------------------

We actually had a legitimate reason not to support the number of values argument 
in the binary representation reader. Indeed, when the binary representation 
is used to code sequence of integers instead of a single integer, it becomes 
ambiguous: the same bitstream may represent several sequences of integers. 
For example, we have:

    >>> BitStream(255)
    11111111
    >>> BitStream([15, 15])
    11111111
    >>> BitStream([3, 7, 3, 1])
    11111111
    >>> BitStream([3, 3, 3, 3])
    11111111

We say that this code is not *self-delimiting*, as there is no way to know 
where is the boundary between the bits coding for different integers. 

For natural numbers with known bounds, we may solve this problem by setting
a number of bits to be used for each integer. However, to do that, we
would have to define and register a new writer for every possible number
of bits. Instead, we register a single but configurable writer, defined
by a writer factory.

Let's define a type tag `uint` whose instances hold a number of bits:

    >>> class uint(object):
    ...     def __init__(self, num_bits):
    ...         self.num_bits = num_bits

Then, we define a factory that given a `uint` instance, 
returns a stream writer:

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

To select a writer, we use the proper instance of type tag:

    >>> BitStream(255, uint(8))
    11111111
    >>> BitStream(255, uint(16))
    0000000011111111
    >>> BitStream(42, uint(8))
    00101010
    >>> BitStream(0, uint(16))
    0000000000000000


**TODO: reader, give details, comment.**

    >>> def read_uint_factory(instance): # use the name factory ?
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

    >>> bitstream.register(uint, reader=read_uint_factory)

    >>> stream = BitStream([0, 1, 2, 3, 4], uint(8))
    >>> stream.read(uint(8))
    0
    >>> stream.read(uint(8), 1)
    [1]
    >>> stream.read(uint(8), 3)
    [2, 3, 4]

