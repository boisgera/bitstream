
Overview
================================================================================

Bitstream is a [Python] library which manages binary data as bit streams:

    >>> from bitstream import BitStream
    >>> BitStream("Hello World!")
    010010000110010101101100011011000110111100100000010101110110111101110010011011000110010000100001


The standard library provides the [struct](https://docs.python.org/2/library/struct.html) 
module to manage binary data. 
If you find its API arcane, consider using bitstream instead[^1]:

[^1]:
    Compare the binary encoding of a sequence of doubles

        >>> data = [1.0, 2.0, 3.0]

    with struct

        >>> import struct
        >>> format = ">{0}d".format(len(data))
        >>> struct.pack(format, *data)
        '?\xf0\x00\x00\x00\x00\x00\x00@\x00\x00\x00\x00\x00\x00\x00@\x08\x00\x00\x00\x00\x00\x00'

    and with bitstream

        >>> from bitstream import BitStream
        >>> stream = BitStream(data)
        >>> stream.read(str)
        '?\xf0\x00\x00\x00\x00\x00\x00@\x00\x00\x00\x00\x00\x00\x00@\x08\x00\x00\x00\x00\x00\x00'



!!! note "Binary Data"



!!! note "Stream Interface"
    You can only read data at the start of a stream 
    and write data at its end.
    This is a very simple way to interact with binary data, but it is also
    the pattern that comes naturally in many applications. 

        >>> stream = BitStream()
        >>> stream.write(True, bool)
        >>> stream.write(False, bool)
        >>> stream.write(-128, int8)
        >>> stream.write("AB", str)
        >>> stream
        10100000000100000101000010
        >>> stream.read(bool, 2)
        [True, False]
        >>> stream.read(int8, 1)
        array([-128], dtype=int8)
        >>> stream.read(str, 2)
        'AB'


    To manage
    binary codes and formats, in my experience, random data access is 
    not a requirement.

    HERE: snapshot ref

!!! note "Python & NumPy" 
    BitStream has built-in support for the common data types 
    with a standard binary layout: bools, ASCII strings, 
    fixed-size integers and floating-point integers. 



        >>> from numpy import *
        >>> dt = 1.0 / 44100.0
        >>> t = r_[0.0:1.0:dt]
        >>> data = cos(2*pi*440.0*t)       
        >>> stream = BitStream(data)

!!! note "Performance" 
    Bitstream is a Python C-extension module that has been
    optimized for the common use cases. Hopefully, it will be fast enough 
    for your needs! 
    Under the hood, the [Cython] language and compiler are used to generate 
    this extension module.

!!! note "Advanced Features"

      - Custom types: 
        The list of supported types and binary 
        representation may be enlarged at will: new readers and writers 
        can be implemented and associated to specific data types.

        See: [Custom types](custom)

      - Snapshots:

        See: [Snapshots](snapshots)

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
