
Custom Writers and Readers
================================================================================

    >>> import bitstream

Definition and Registration of Writers and Readers
--------------------------------------------------------------------------------

Let's define a writer for the binary representation of natural numbers:

    >>> def write_integer(stream, data):
    ...     if isinstance(data, list):
    ...         for integer in data:
    ...             write_integer(stream, integer)
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
    >>> write_integer(stream, 42)
    >>> stream
    101010
    >>> write_integer(stream, [1, 2, 3])
    >>> stream
    10101011011

Then, we can associate it to the type `int`:

    >>> bitstream.register(int, writer=write_integer)

After this step, `BitStream` will redirect all data of type `int` to this writer:

    >>> BitStream(42)
    101010
    >>> BitStream([1, 2, 3])
    11011

If the type information is explicit, other kind of data can use this writer too:

    >>> BitStream(uint8(42), int)
    101010
    >>> BitStream("42", int)
    101010

A possible implementation of the corresponding reader is given by:

    >>> def read_integer(stream, n=None):
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

    >>> read_integer(BitStream(42))
    42

Once this reader is registered with

    >>> bitstream.register(int, reader=read_integer)

the calls to `read_integer` can be made through the `read` method of `BitStream`.

    >>> BitStream(42).read(int)
    42

In all readers, the second argument of readers, named `n`, 
represents the number of values to read from the stream. 
Here, this argument is not supported, instead any call to this reader 
interprets the complete stream content as a single value.

Writer and Reader Factories
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

