
API Reference
================================================================================

We assume in the sequel that all symbols of NumPy and BitStream are available:

    >>> from numpy import *
    >>> from bitstream import *


Constructor
--------------------------------------------------------------------------------

Most of the library features are available through the `BitStream` class:

??? note "`BitStream()`"
    Create an empty bitstream.

    <h5>Usage</h5>

        >>> stream = BitStream()

??? note "`BitStream(data, type=None)`"
    Create an empty bitstream,
    then call the `write` method.

    <h5>Arguments</h5>

      - `data` is the data to be encoded.

        The data type should be consistent with the `type` argument.

      - `type` is a type identifier (such as `bool`, `bytes`, `int8`, etc.).

        `type` can be omitted if `data` is an instance
        of a registered type or a
        list or 1d NumPy array of such 
        instances.

    <h5>Usage</h5>

        >>> stream = BitStream([False, True])
        >>> stream = BitStream(b"Hello", bytes)
        >>> stream = BitStream(42, uint8)

    <h5>See also</h5>

      - [Read / Write](#read-write)

Read / Write
--------------------------------------------------------------------------------

??? note "`BitStream.write(self, data, type=None)`"
    Encode `data` and append it to the stream.

    <h5>Arguments</h5>

      - `data` is the data to be encoded.

        Its type should be consistent with the `type` argument.

      - `type` is a type identifier (such as `bool`, `str`, `int8`, etc.).

        `type` can be omitted if `data`
        is an instance
        of a registered type or a
        list or 1d NumPy array of such 
        instances.

    <h5>Usage</h5>

        >>> stream = BitStream()
        >>> stream.write(True, bool)       # explicit bool type
        >>> stream.write(False)            # implicit bool type
        >>> stream.write(3*[False], bool)  # list (explicit type)
        >>> stream.write(3*[True])         # list (implicit type)
        >>> stream.write(b"AB", bytes)     # bytes
        >>> stream.write(-128, int8)       # signed 8 bit integer

    <h5>See also</h5>

      - [Builtin Types](../types)

      - [Custom Types](../custom)



??? note "`BitStream.read(self, type=None, n=None)`"
    Decode and consume `n` items of `data` from the start of the stream.

    <h5>Arguments</h5>

      - `type`: type identifier (such as `bool`, `bytes`, `int8`, etc.)
     
        If `type` is `None` a bitstream is returned.

      - `n`: number of items to read

        For most types, `n=None` reads one item, 
        but some types use a different convention.

    <h5>Returns</h5>

      - `data`: `n` items of data

        The type of `data` depends on `type` and `n`. For built-in types:

        `type`                   | `n = None`         | `n = 0, 1, 2, ...` 
        -------------------------|--------------------|----------------------------------------
        `bool`                   | `bool`             | `list` of bools
        `BitStream`              | `BitStream`        | `BitStream`
        `bytes`                  | `bytes`            | `bytes`
        `numpy.uint8`            | `numpy.uint8`      | `numpy.array`
        `numpy.int8`             | `numpy.int8`       | `numpy.array`
        `numpy.uint16`           | `numpy.int16`      | `numpy.array`
        ...                      | ...                | ...
        `float`                  | `float`            | `numpy.array`

    <h5>Usage</h5>

        >>> stream = BitStream(b"Hello World!")
        >>> stream.read(bytes, 2)
        'He'
        >>> stream.read(bool)
        False
        >>> stream.read(bool, 7)
        [True, True, False, True, True, False, False]
        >>> stream.read(uint8, 2)
        array([108, 111], dtype=uint8)
        >>> stream.read(uint8)
        32
        >>> stream.read(bytes)
        'World!'

    <h5>See also</h5>

      - [Builtin Types](../types)

      - [Custom Types](../custom)



String Representation
--------------------------------------------------------------------------------

??? note "`BitStream.__str__(self)`"
    Represent the stream as a string of `'0'` and `'1'`.

    <h5>Usage</h5>

        >>> print(BitStream(b"ABC"))
        010000010100001001000011



??? note "`BitStream.__repr__(self)`"
    Represent the stream as a string of `'0'` and `'1'`.

    <h5>Usage</h5>

        >>> BitStream(b"ABC")
        010000010100001001000011


Copy
--------------------------------------------------------------------------------

Bitstreams can be copied non-destructively with `BitStream.copy`. 
They also support the interface required by the standard library `copy` module.


??? note "`BitStream.copy(self, n=None)`"
    Copy (partially or totally) the stream.

    Copies do not consume the stream they read.

    <h5>Arguments</h5>

      - `n`: unsigned integer of `None`.

        The number of bits to copy from the start of the stream. 
        The full stream is copied if `n` is None.

    <h5>Returns</h5>

      - `stream`: a bitstream.

    <h5>Raises</h5>

      - `ReadError` if `n` is larger than the length of the stream.

    <h5>Usage</h5>

        >>> stream = BitStream(b"A")
        >>> stream
        01000001
        >>> copy = stream.copy()
        >>> copy
        01000001
        >>> stream
        01000001
        >>> stream.copy(4)
        0100
        >>> stream
        01000001
        >>> stream.read(BitStream, 4)
        0100
        >>> stream
        0001

??? note "`BitStream.__copy__(self)`"
    Bitstream shallow copy.

    <h5>Usage</h5>

        >>> from copy import copy
        >>> stream = BitStream(b"A")
        >>> stream
        01000001
        >>> copy(stream)
        01000001
        >>> stream
        01000001

??? note "`BitStream.__deepcopy__(self, memo)`"
    Bitstream deep copy.

    <h5>Usage</h5>

        >>> from copy import deepcopy
        >>> stream = BitStream(b"A")
        >>> stream
        01000001
        >>> deepcopy(stream)
        01000001
        >>> stream
        01000001


Length and Comparison
--------------------------------------------------------------------------------

??? note "`BitStream.__len__(self, other)`"
    Return the bitstream length in bits.

    <h5>Usage</h5>

        >>> stream = BitStream([True, False])
        >>> len(stream) 
        2

        >>> stream = BitStream(b"ABC")
        >>> len(stream)
        24
        >>> len(stream) // 8
        3
        >>> len(stream) % 8
        0


??? note "`BitStream.__eq__(self, other)`"
    Equality operator

    <h5>Usage</h5>

        >>> BitStream(True) == BitStream(True)
        True
        >>> BitStream(True) == BitStream([True])
        True
        >>> BitStream(True) == BitStream(False)
        False
        >>> BitStream(True) == BitStream([True, False])
        False

        >>> ord(b"A")
        65
        >>> BitStream(b"A") == BitStream(65, uint8)
        True
        >>> BitStream(b"A") == BitStream(66, uint8)
        False
  

??? note "`BitStream.__ne__(self, other)`"
    Inequality operator

    <h5>Usage</h5>

        >>> BitStream(True) != BitStream(True)
        False
        >>> BitStream(True) != BitStream([True])
        False
        >>> BitStream(True) != BitStream(False)
        True
        >>> BitStream(True) != BitStream([True, False])
        True

        >>> ord(b"A")
        65
        >>> BitStream(b"A") != BitStream(65, uint8)
        False
        >>> BitStream(b"A") != BitStream(66, uint8)
        True

??? note "`BitStream.__hash__(self)`"
    Compute a bitstream hash 

    The computed hash is consistent with the equality operator.


Custom Types
--------------------------------------------------------------------------------

User-defined binary codecs can be bound to type identifiers.
For details, refer to [Custom Types](../custom).

??? note "`register(type, reader=None, writer=None)`"
    Register a binary encoding (and/or) decoding.

      - `type` is a type identifier (type or "type tag").

      - `reader` is a function with signature `reader(stream, n=None)`.

      - `writer` is a function with signature `writer(stream, data)`.


Exceptions
--------------------------------------------------------------------------------

??? note "`ReadError`"
    Exception raised when a binary decoding is impossible.

??? note "`WriteError`"
    Exception raised when a binary encoding is impossible.


Snapshots
--------------------------------------------------------------------------------

Save and restore stream states. 
For details, refer to [Snapshots](snapshots).

As a user, you should not rely on the implementation of `State` 
which is an internal detail: 
instances of `State` have no public attribute, no public method,
they can only be produced by `save` and consumed by `restore`.

??? note "`State`"
    The opaque type of stream state.

??? note "`BitStream.save(self)`"

    Return a `State` instance

??? note "`BitStream.restore(self, state)`"

    Restore a previous stream state.

    Raise a `ValueError` if the state is invalid.


