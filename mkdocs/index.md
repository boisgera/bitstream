
Overview
================================================================================

Bitstream is a [Python] library to manage binary data as bitstreams:

    >>> from bitstream import BitStream
    >>> BitStream(b"Hello World!")
    010010000110010101101100011011000110111100100000010101110110111101110010011011000110010000100001

If you need to deal with existing binary file formats,
or design your own binary formats or
experiment with data compression algorithms, etc. 
and if the Python standard library doesn't work for you,
you may be interested in bitstream.
Read this section and have a look at the [example applications](examples) 
to see if it is what you need.


The main features are:

!!! note "Easy to use"

    [Bitstreams](https://en.wikipedia.org/wiki/Bitstream) are a simple abstraction.
    They behave like communication channels: 
    you can only write data at one end of it 
    and read data at the other end, in the same order.
    So you only need to know how to create a stream, write into it
    and read it to use this library:

        >>> stream = BitStream()
        >>> stream.write(b"Hello")
        >>> stream.write(b" World!")
        >>> stream.read(bytes, 5) # doctest: +BYTES
        b'Hello'
        >>> stream.read(bytes, 7) # doctest: +BYTES
        b' World!'

    This simple way to manage binary data is good enough for a surprisingly
    large number of use cases. 
    It should be much easier to use than
    [struct](https://docs.python.org/2/library/struct.html) and 
    [array](https://docs.python.org/2/library/array.html), 
    the modules that the standard Python library provides for this task. 
    

!!! note "Works at the bit and byte level."

    Compact codes (for example [Huffman codes](https://en.wikipedia.org/wiki/Huffman_coding))
    do not always represent data with an entire number of bytes.
    Since bitstream supports bits and not merely bytes, such codes
    are implemented with the same API.
    For example, the [unary coding](https://en.wikipedia.org/wiki/Unary_coding) 
    of a sequence natural numbers requires only a few lines:

        >>> data = [0, 1, 2, 3, 4, 5, 6, 7, 8, 9]
        >>> stream = BitStream()
        >>> for number in data:
        ...     stream.write(number * [True] + [False])
        ... 
        >>> stream
        0101101110111101111101111110111111101111111101111111110



!!! note "Supports Python & NumPy types" 

    BitStream has built-in support for the common data types 
    with a standard binary layout: bools, bytes, 
    fixed-size integers and floating-point integers. 

        >>> stream = BitStream()
        >>> stream.write(True, bool)
        >>> stream.write(False, bool)
        >>> from numpy import int8
        >>> stream.write(-128, int8)
        >>> stream.write(b"AB", bytes)
        >>> stream
        10100000000100000101000010
        >>> stream.read(bool, 2)
        [True, False]
        >>> stream.read(int8, 1)
        array([-128], dtype=int8)
        >>> stream.read(bytes, 2) # doctest: +BYTES
        b'AB'

    NumPy arrays are a convenient way to deal with sequences of homogeneous data:

        >>> from numpy import *
        >>> dt = 1.0 / 44100.0
        >>> t = r_[0.0:1.0:dt]
        >>> data = cos(2*pi*440.0*t)       
        >>> stream = BitStream(data)

    Refer to the [Built-in types](types) section for more details.


!!! note "Advanced features"

      - **Performance.** Bitstream is a Python C-extension module that has been
        optimized for the common use cases. Hopefully, it will be fast enough 
        for your needs! 
        Under the hood, the [Cython] language and compiler are used to generate 
        this extension module.

      - **Custom types.**
        The list of supported types and binary 
        representation may be enlarged at will: new readers and writers 
        can be implemented and associated to specific data types.

        See also: [Custom types](custom).

      - **Snapshots.** At times, the stream abstraction is too simple,
        for example when you need to lookahead into the stream without
        consuming its content. Snapshots are an extension of the stream
        model that solve this kind of issue
        since they provide a "time machine" to restore a stream 
        to an earlier state.

        See also: [Snapshots](snapshots).

!!! note "Open Source"
    Bitstream  is distributed under a [MIT license]. 
    The development takes place on [GitHub] and 
    releases are distributed on [PyPI].




[Markdown]: http://daringfireball.net/projects/markdown/
[CC-BY-3.0]: http://creativecommons.org/licenses/by/3.0/
[struct]: http://docs.python.org/2/library/struct.html
[Python]: http://www.python.org/
[Cython]: http://www.cython.org
[bitarray]: https://pypi.python.org/pypi/bitarray
[bitstring]: https://code.google.com/p/python-bitstring
[MIT license]: https://github.com/boisgera/bitstream/blob/master/LICENSE.txt
[GitHub]: https://github.com/boisgera/bitstream
[PyPI]: https://pypi.python.org/pypi/bitstream/
