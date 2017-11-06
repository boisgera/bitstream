
Overview of Bitstream Features
================================================================================ 

    >>> from numpy import *
    >>> from bitstream import *

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

