#!/usr/bin/env python

from numpy import *
from bitstream import *


# TODO: have templates and generate the doctest containers.
#
# TODO: benchmark and aggregate the results: for example, parametrize by type 
#       and size and show the % of variation wrt the way the type is specified,
#       variation linked to alignment, etc.
#
# TODO: go away from functions ? Use strings instead and collect in __test__ ?
#       I am not sure that would bring anything ...
#
# TODO: extract a one-liner from the docstring ? (if there is one, followed by
#       a blankline).

def do_nothing():
    pass

def write_bools_1_by_1_loop_only():
    """
    >>> bools = 44100 * 2 * 8 * [True, False]
    >>> stream = BitStream()
    >>> for _bool in bools:
    ...     do_nothing()
    """
    pass

def write_bools_1_by_1_auto_type_not_aligned():
    """
    >>> bools = 44100 * 2 * 8 * [True, False]
    >>> stream = BitStream(4 * [True])
    >>> for _bool in bools:
    ...     stream.write(_bool)
    """
    pass

def write_bools_1_by_1_auto_type():
    """
    >>> bools = 44100 * 2 * 8 * [True, False]
    >>> stream = BitStream()
    >>> for _bool in bools:
    ...     stream.write(_bool)
    """
    pass

def write_bools_1_by_1_given_type():
    """
    >>> bools = 44100 * 2 * 8 * [True, False]
    >>> stream = BitStream()
    >>> for _bool in bools:
    ...     stream.write(_bool, bool)
    """
    pass

def write_bools_bool_1_by_1_specialized_by_type():
    """
    >>> bools = 44100 * 2 * 8 * [True, False]
    >>> stream = BitStream()
    >>> for _bool in bools:
    ...     write_bool(stream, _bool)
    """
    pass

def write_bools_0_1_1_by_1_specialized_by_type():
    """
    >>> bools = 44100 * 2 * 8 * [0, 1]
    >>> stream = BitStream()
    >>> for _bool in bools:
    ...     write_bool(stream, _bool)
    """
    pass

def write_bools_numpy_bool_1_by_1_specialized_by_type():
    """
    >>> bools = 44100 * 2 * 8 * [bool_(True), bool_(False)]
    >>> stream = BitStream()
    >>> for _bool in bools:
    ...     write_bool(stream, _bool)
    """
    pass

def write_bools_str_1_by_1_specialized_by_type():
    """
    >>> bools = 44100 * 2 * 8 * ["T", ""]
    >>> stream = BitStream()
    >>> for _bool in bools:
    ...     write_bool(stream, _bool)
    """
    pass


def write_bools_8_by_8_loop_only():
    """
    >>> bools = 44100 * 2 * 2 * [4 * [True, False]]
    >>> stream = BitStream()
    >>> for _bool in bools:
    ...     do_nothing()
    """
    pass

def write_bools_8_by_8_auto_type_not_aligned():
    """
    >>> bools = 44100 * 2 * 2 * [4 * [True, False]]
    >>> stream = BitStream(4 * [True])
    >>> for _bools in bools:
    ...     stream.write(_bools)
    """

def write_bools_8_by_8_auto_type():
    """
    >>> bools = 44100 * 2 * 2 * [4 * [True, False]]
    >>> stream = BitStream()
    >>> for _bools in bools:
    ...     stream.write(_bools)
    """

def write_bools_8_by_8_given_type():
    """
    >>> bools = 44100 * 2 * 2 * [4 * [True, False]]
    >>> stream = BitStream()
    >>> for _bools in bools:
    ...     stream.write(_bools, bool)
    """

def write_bools_list_bools_8_by_8_specialized_by_type():
    """
    >>> bools = 44100 * 2 * 2 * [4 * [True, False]]
    >>> stream = BitStream()
    >>> for bools_ in bools:
    ...     write_bool(stream, bools_)
    """

def write_bools_array_bools_8_by_8_specialized_by_type():
    """
    >>> bools = 44100 * 2 * 2 * [array(4 * [True, False], dtype=bool)]
    >>> stream = BitStream()
    >>> for bools_ in bools:
    ...     write_bool(stream, bools_)
    """

def write_bools_array_uint8_8_by_8_specialized_by_type():
    """
    >>> bools = 44100 * 2 * 2 * [array(4 * [0, 255], dtype=uint8)]
    >>> stream = BitStream()
    >>> for bools_ in bools:
    ...     write_bool(stream, bools_)
    """

def write_bools_array_uint16_8_by_8_specialized_by_type():
    """
    >>> bools = 44100 * 2 * 2 * [array(4 * [0, 255], dtype=uint16)]
    >>> stream = BitStream()
    >>> for bools_ in bools:
    ...     write_bool(stream, bools_)
    """

def write_bools_16_by_16_auto_type_not_aligned():
    """
    >>> bools = 44100 * 2 * [8 * [True, False]]
    >>> stream = BitStream(4 * [True])
    >>> for _bools in bools:
    ...     stream.write(_bools)
    """

def write_bools_16_by_16_auto_type():
    """
    >>> bools = 44100 * 2 * [8 * [True, False]]
    >>> stream = BitStream()
    >>> for _bools in bools:
    ...     stream.write(_bools)
    """

def write_bools_16_by_16_given_type():
    """
    >>> bools = 44100 * 2 * [8 * [True, False]]
    >>> stream = BitStream()
    >>> for _bools in bools:
    ...     stream.write(_bools, bool)
    """

def write_bools_list_bools_16_by_16_specialized_by_type():
    """
    >>> bools = 44100 * 2 * [8 * [True, False]]
    >>> stream = BitStream()
    >>> for _bools in bools:
    ...     write_bool(stream, _bools)
    """

def write_bools_array_bools_16_by_16_specialized_by_type():
    """
    >>> bools = 44100 * 2 * [array(8 * [True, False], dtype=bool)]
    >>> stream = BitStream()
    >>> for _bools in bools:
    ...     write_bool(stream, _bools)
    """

def write_bools_32_by_32_auto_type_not_aligned():
    """
    >>> bools = 44100 * [16 * [True, False]]
    >>> stream = BitStream(4 * [True])
    >>> for _bools in bools:
    ...     stream.write(_bools)
    """

def write_bools_32_by_32_auto_type():
    """
    >>> bools = 44100 * [16 * [True, False]]
    >>> stream = BitStream()
    >>> for _bools in bools:
    ...     stream.write(_bools)
    """

def write_bools_32_by_32_given_type():
    """
    >>> bools = 44100 * [16 * [True, False]]
    >>> stream = BitStream()
    >>> for _bools in bools:
    ...     stream.write(_bools, bool)
    """

def write_bools_list_bools_32_by_32_specialized_by_type():
    """
    >>> bools = 44100 * [16 * [True, False]]
    >>> stream = BitStream()
    >>> for _bools in bools:
    ...     write_bool(stream, _bools)
    """

def write_bools_array_bools_32_by_32_specialized_by_type():
    """
    >>> bools = 44100 * [array(16 * [True, False], dtype=bool)]
    >>> stream = BitStream()
    >>> for _bools in bools:
    ...     write_bool(stream, _bools)
    """

#---
def write_bools_64_by_64_auto_type_not_aligned():
    """
    >>> bools = (44100 / 2) * [32 * [True, False]]
    >>> stream = BitStream(4 * [True])
    >>> for _bools in bools:
    ...     stream.write(_bools)
    """

def write_bools_64_by_64_auto_type():
    """
    >>> bools = (44100 / 2) * [32 * [True, False]]
    >>> stream = BitStream()
    >>> for _bools in bools:
    ...     stream.write(_bools)
    """

def write_bools_64_by_64_given_type():
    """
    >>> bools = (44100 / 2) * [32 * [True, False]]
    >>> stream = BitStream()
    >>> for _bools in bools:
    ...     stream.write(_bools, bool)
    """

def write_bools_list_bools_64_by_64_specialized_by_type():
    """
    >>> bools = (44100 / 2) * [32 * [True, False]]
    >>> stream = BitStream()
    >>> for _bools in bools:
    ...     write_bool(stream, _bools)
    """

def write_bools_array_bools_64_by_64_specialized_by_type():
    """
    >>> bools = (44100 / 2) * [array(32 * [True, False], dtype=bool)]
    >>> stream = BitStream()
    >>> for _bools in bools:
    ...     write_bool(stream, _bools)
    """

def write_bools_256_by_256_auto_type_not_aligned():
    """
    >>> bools = (44100 / 8) * [128 * [True, False]]
    >>> stream = BitStream(4 * [True])
    >>> for _bools in bools:
    ...     stream.write(_bools)
    """

def write_bools_256_by_256_auto_type():
    """
    >>> bools = (44100 / 8) * [128 * [True, False]]
    >>> stream = BitStream()
    >>> for _bools in bools:
    ...     stream.write(_bools)
    """

def write_bools_256_by_256_given_type():
    """
    >>> bools = (44100 / 8) * [128 * [True, False]]
    >>> stream = BitStream()
    >>> for _bools in bools:
    ...     stream.write(_bools, bool)
    """

def write_bools_list_bools_256_by_256_specialized_by_type():
    """
    >>> bools = (44100 / 8) * [128 * [True, False]]
    >>> stream = BitStream()
    >>> for _bools in bools:
    ...     write_bool(stream, _bools)
    """

def write_bools_array_bools_256_by_256_specialized_by_type():
    """
    >>> bools = (44100 / 8) * [array(128 * [True, False], dtype=bool)]
    >>> stream = BitStream()
    >>> for _bools in bools:
    ...     write_bool(stream, _bools)
    """

def write_bools_1024_by_1024_auto_type_not_aligned():
    """
    >>> bools = (44100 / 32) * [512 * [True, False]]
    >>> stream = BitStream(4 * [True])
    >>> for _bools in bools:
    ...     stream.write(_bools)
    """

def write_bools_1024_by_1024_auto_type():
    """
    >>> bools = (44100 / 32) * [512 * [True, False]]
    >>> stream = BitStream()
    >>> for _bools in bools:
    ...     stream.write(_bools)
    """

def write_bools_1024_by_1024_given_type():
    """
    >>> bools = (44100 / 32) * [512 * [True, False]]
    >>> stream = BitStream()
    >>> for _bools in bools:
    ...     stream.write(_bools, bool)
    """

def write_bools_list_bools_1024_by_1024_specialized_by_type():
    """
    >>> bools = (44100 / 32) * [512 * [True, False]]
    >>> stream = BitStream()
    >>> for _bools in bools:
    ...     write_bool(stream, _bools)
    """

def write_bools_array_bools_1024_by_1024_specialized_by_type():
    """
    >>> bools = (44100 / 32) * [array(512 * [True, False], dtype=bool)]
    >>> stream = BitStream()
    >>> for _bools in bools:
    ...     write_bool(stream, _bools)
    """

def write_bools_all_not_aligned():
    """
    >>> bools = 44100 * 16 * [True, False]
    >>> stream = BitStream(4 * [True])
    >>> stream.write(bools)
    """
    pass

def write_bools_list_bools_all():
    """
    >>> bools = 44100 * 16 * [True, False]
    >>> stream = BitStream()
    >>> stream.write(bools)
    """
    pass

def write_bools_array_bools_all():
    """
    >>> bools = array(44100 * 16 * [True, False], dtype=bool)
    >>> stream = BitStream()
    >>> stream.write(bools)
    """
    pass

def read_bools_1_by_1():
    """
    >>> bools = 44100 * 2 * 8 * [True, False]
    >>> stream = BitStream(bools)
    >>> for i in range(len(stream)):
    ...     stream.read(bool)
    """
    pass

def read_bools_1_by_1_specialized_type():
    """
    >>> bools = 44100 * 2 * 8 * [True, False]
    >>> stream = BitStream(bools)
    >>> for i in range(len(stream)):
    ...     read_bool(stream)
    """
    pass


# ------------------------------------------------------------------------------

# for single uint8 write, 2/3 of the time is spent in the `array` cast.
# we should aim for 0.1 to 0.05 here, not 0.4 or 0.5 ! (see the bool
# perf on 8-bit write). Need a fast path, avoid array cast if we can,
# I don't know ... dont create a _write_uint functions with array type
# but a single function and use the array type internally when we can't
# avoid it (after the fast paths). Do we ever need the array stuff when
# the input arguments is NOT an array ? Is the cast helping when a list
# is given for example ? Unclear ...
#
# TODO: for multiple uint8 write, remove slicing (increases the time
#       artificially)

def write_uint8_1_by_1_auto_type_not_aligned():
    """
    >>> uint8s = 44100 * 2 * 2 * [uint8(1)]
    >>> stream = BitStream(4 * [True])
    >>> for _uint8 in uint8s:
    ...     stream.write(_uint8)
    """

def write_uint8_1_by_1_auto_type():
    """
    >>> uint8s = 44100 * 2 * 2 * [uint8(1)]
    >>> stream = BitStream()
    >>> for _uint8 in uint8s:
    ...     stream.write(_uint8)
    """

def write_uint8_int_1_by_1_given_type():
    """
    >>> ints = 44100 * 2 * 2 * [1]
    >>> stream = BitStream()
    >>> for _int in ints:
    ...     stream.write(_int, uint8)
    """

def write_uint8_uint8_1_by_1_given_type():
    """
    >>> uint8s = 44100 * 2 * 2 * [uint8(1)]
    >>> stream = BitStream()
    >>> for _uint8 in uint8s:
    ...     stream.write(_uint8, uint8)
    """

def write_uint8_int_1_by_1_specialized_type():
    """
    >>> ints = 44100 * 2 * 2 * [1]
    >>> stream = BitStream()
    >>> for _int in ints:
    ...     write_uint8(stream, _int)
    """

def write_uint8_uint8_1_by_1_specialized_type():
    """
    >>> uint8s = 44100 * 2 * 2 * [uint8(1)]
    >>> stream = BitStream()
    >>> for _uint8 in uint8s:
    ...     write_uint8(stream, _uint8)
    """

def write_uint8_list_1_by_1_specialized_type():
    """
    >>> ints = 44100 * 2 * 2 * [[1]]
    >>> stream = BitStream()
    >>> for _int in ints:
    ...     write_uint8(stream, _int)
    """

def write_uint8_array_1_by_1_specialized_type():
    """
    >>> uint8s = 44100 * 2 * 2 * [array(1, uint8)]
    >>> stream = BitStream()
    >>> for _uint8 in uint8s:
    ...     write_uint8(stream, _uint8)
    """

def write_uint8_1_by_1_loop_only():
    """
    >>> ints = 44100 * 2 * 2 * [[1]]
    >>> stream = BitStream()
    >>> for _int in ints:
    ...     do_nothing()
    """

def write_uint8_list_2_by_2_specialized_type():
    """
    >>> ints = 44100 * 2 * [[1, 1]]
    >>> stream = BitStream()
    >>> for _ints in ints:
    ...     write_uint8(stream, _ints)
    """

def write_uint8_array_2_by_2_specialized_type():
    """
    >>> uint8s = 44100 * 2 * [array([1, 1], uint8)]
    >>> stream = BitStream()
    >>> for _uint8s in uint8s:
    ...     write_uint8(stream, _uint8s)
    """

def write_uint8_list_2_by_2_specialized_type_not_aligned():
    """
    >>> ints = 44100 * 2 * [2 * [uint8(1)]]
    >>> stream = BitStream(4 * [True])
    >>> for _ints in ints:
    ...     write_uint8(stream, _ints)
    """

def write_uint8_list_4_by_4_specialized_type():
    """
    >>> ints = 44100 * [[1, 1, 1, 1]]
    >>> stream = BitStream()
    >>> for _ints in ints:
    ...     write_uint8(stream, _ints)
    """

def write_uint8_array_4_by_4_specialized_type():
    """
    >>> uint8s = 44100 * [array([1, 1, 1, 1], uint8)]
    >>> stream = BitStream()
    >>> for _uint8s in uint8s:
    ...     write_uint8(stream, _uint8s)
    """

def write_uint8_list_4_by_4_specialized_type_not_aligned():
    """
    >>> ints = 44100 * [[1, 1, 1, 1]]
    >>> stream = BitStream(4 * [True])
    >>> for _ints in ints:
    ...     write_uint8(stream, _ints)
    """

def write_uint8_list_8_by_8_specialized_type():
    """
    >>> ints = (44100 / 2) * [8 * [1]]
    >>> stream = BitStream()
    >>> for _ints in ints:
    ...     write_uint8(stream, _ints)
    """

def write_uint8_array_8_by_8_specialized_type():
    """
    >>> uint8s = (44100 / 2) * [array(8 * [1], uint8)]
    >>> stream = BitStream()
    >>> for _uint8s in uint8s:
    ...     write_uint8(stream, _uint8s)
    """

def write_uint8_list_8_by_8_specialized_type_not_aligned():
    """
    >>> ints = (44100 / 2) * [8 * [1]]
    >>> stream = BitStream(4 * [True])
    >>> for _ints in ints:
    ...     write_uint8(stream, _ints)
    """

def write_uint8_list_16_by_16():
    """
    >>> uint8s = ones(44100 * 2 * 2, uint8)
    >>> stream = BitStream()
    >>> for i in range(len(uint8s) / 16):
    ...     stream.write(uint8s[16*i:16*(i+1)])
    """

def write_uint8_list_16_by_16_not_aligned():
    """
    >>> uint8s = ones(44100 * 2 * 2, uint8)
    >>> stream = BitStream(4 * [True])
    >>> for i in range(len(uint8s) / 16):
    ...     stream.write(uint8s[16*i:16*(i+1)])
    """

def write_uint8_array_32_by_32():
    """
    >>> uint8s = ones(44100 * 2 * 2, uint8)
    >>> stream = BitStream()
    >>> for i in range(len(uint8s) / 32):
    ...     stream.write(uint8s[32*i:32*(i+1)])
    """

def write_uint8_array_32_by_32_not_aligned():
    """
    >>> import numpy
    >>> uint8s = ones(44100 * 2 * 2, uint8)
    >>> stream = BitStream(4 * [True])
    >>> for i in range(len(uint8s) / 32):
    ...     stream.write(uint8s[32*i:32*(i+1)])
    """

def write_uint8_array_all_not_aligned():
    """
    >>> uint8s = list(ones(44100 * 2 * 2, uint8))
    >>> stream = BitStream(4 * [True])
    >>> stream.write(uint8s)
    """

def write_uint8_list_all():
    """
    >>> uint8s = list(ones(44100 * 2 * 2, uint8))
    >>> stream = BitStream()
    >>> stream.write(uint8s)
    """

def write_uint8_array_all():
    """
    >>> uint8s = list(ones(44100 * 2 * 2, uint8))
    >>> stream = BitStream()
    >>> stream.write(uint8s)
    """

def read_uint8_1_by_1_not_aligned():
    """
    >>> n = 44100 * 2 * 2
    >>> stream = BitStream(4 * [True])
    >>> stream.write(ones(n, dtype=uint8))
    >>> stream.read(bool, 4)
    [True, True, True, True]
    >>> for i in range(n):
    ...     stream.read(uint8, 1)
    """

def read_uint8_1_by_1():
    """
    >>> n = 44100 * 2 * 2
    >>> stream = BitStream()
    >>> stream.write(ones(n, dtype=uint8))
    >>> for i in range(n):
    ...     stream.read(uint8, 1)
    """

def read_uint8_2_by_2():
    """
    >>> n = 44100 * 2 * 2
    >>> stream = BitStream()
    >>> stream.write(ones(n, dtype=uint8))
    >>> for i in range(n / 2):
    ...     stream.read(uint8, 2)
    """

def read_uint8_4_by_4():
    """
    >>> n = 44100 * 2 * 2
    >>> stream = BitStream()
    >>> stream.write(ones(n, dtype=uint8))
    >>> for i in range(n / 4):
    ...     stream.read(uint8, 4)
    """

def read_uint8_8_by_8():
    """
    >>> n = 44100 * 2 * 2
    >>> stream = BitStream()
    >>> stream.write(ones(n, dtype=uint8))
    >>> for i in range(n / 8):
    ...     stream.read(uint8, 8)
    """

def read_uint8_all():
    """
    >>> n = 44100 * 2 * 2
    >>> stream = BitStream()
    >>> stream.write(ones(n, dtype=uint8))
    >>> stream.read(uint8, n)
    """


# ------------------------------------------------------------------------------

def write_int8_1_by_1_auto_type_not_aligned():
    """
    >>> import numpy
    >>> int8s = ones(44100 * 2 * 2, int8)
    >>> stream = BitStream(4 * [True])
    >>> for int8 in int8s:
    ...     stream.write(int8)
    """

def write_int8_1_by_1_auto_type():
    """
    >>> import numpy
    >>> int8s = ones(44100 * 2 * 2, int8)
    >>> stream = BitStream()
    >>> for int8_ in int8s:
    ...     stream.write(int8_)
    """

def write_int8_1_by_1_given_type():
    """
    >>> import numpy
    >>> int8 = int8
    >>> int8s = ones(44100 * 2 * 2, int8)
    >>> stream = BitStream()
    >>> for int8_ in int8s:
    ...     stream.write(int8_, int8)
    """

def write_int8_1_by_1_specialized_type():
    """
    >>> import numpy
    >>> int8s = ones(44100 * 2 * 2, int8)
    >>> stream = BitStream()
    >>> for int8_ in int8s:
    ...     write_int8(stream, int8_)
    """

def write_int8_1_by_1_loop_only():
    """
    >>> import numpy
    >>> int8s = ones(44100 * 2 * 2, int8)
    >>> stream = BitStream()
    >>> for int8_ in int8s:
    ...     do_nothing()
    """

def write_int8_2_by_2():
    """
    >>> import numpy
    >>> int8s = ones(44100 * 2 * 2, int8)
    >>> stream = BitStream()
    >>> for i in range(len(int8s) / 2):
    ...     stream.write(int8s[i:i+2])
    """

def write_int8_2_by_2_not_aligned():
    """
    >>> import numpy
    >>> int8s = ones(44100 * 2 * 2, int8)
    >>> stream = BitStream(4 * [True])
    >>> for i in range(len(int8s) / 2):
    ...     stream.write(int8s[2*i:2*(i+1)])
    """

def write_int8_4_by_4():
    """
    >>> import numpy
    >>> int8s = ones(44100 * 2 * 2, int8)
    >>> stream = BitStream()
    >>> for i in range(len(int8s) / 4):
    ...     stream.write(int8s[4*i:4*(i+1)])
    """

def write_int8_4_by_4_not_aligned():
    """
    >>> import numpy
    >>> int8s = ones(44100 * 2 * 2, int8)
    >>> stream = BitStream(4 * [True])
    >>> for i in range(len(int8s) / 4):
    ...     stream.write(int8s[4*i:4*(i+1)])
    """

def write_int8_8_by_8():
    """
    >>> import numpy
    >>> int8s = ones(44100 * 2 * 2, int8)
    >>> stream = BitStream()
    >>> for i in range(len(int8s) / 8):
    ...     stream.write(int8s[8*i:8*(i+1)])
    """

def write_int8_8_by_8_not_aligned():
    """
    >>> import numpy
    >>> int8s = ones(44100 * 2 * 2, int8)
    >>> stream = BitStream(4 * [True])
    >>> for i in range(len(int8s) / 8):
    ...     stream.write(int8s[8*i:8*(i+1)])
    """

def write_int8_16_by_16():
    """
    >>> import numpy
    >>> int8s = ones(44100 * 2 * 2, int8)
    >>> stream = BitStream()
    >>> for i in range(len(int8s) / 16):
    ...     stream.write(int8s[16*i:16*(i+1)])
    """

def write_int8_16_by_16_not_aligned():
    """
    >>> import numpy
    >>> int8s = ones(44100 * 2 * 2, int8)
    >>> stream = BitStream(4 * [True])
    >>> for i in range(len(int8s) / 16):
    ...     stream.write(int8s[16*i:16*(i+1)])
    """

def write_int8_32_by_32():
    """
    >>> import numpy
    >>> int8s = ones(44100 * 2 * 2, int8)
    >>> stream = BitStream()
    >>> for i in range(len(int8s) / 32):
    ...     stream.write(int8s[32*i:32*(i+1)])
    """

def write_int8_32_by_32_not_aligned():
    """
    >>> import numpy
    >>> int8s = ones(44100 * 2 * 2, int8)
    >>> stream = BitStream(4 * [True])
    >>> for i in range(len(int8s) / 32):
    ...     stream.write(int8s[32*i:32*(i+1)])
    """

def write_int8_all_not_aligned():
    """
    >>> import numpy
    >>> int8s = ones(44100 * 2 * 2, int8)
    >>> stream = BitStream(4 * [True])
    >>> stream.write(int8s)
    """

def write_int8_all():
    """
    >>> import numpy
    >>> int8s = ones(44100 * 2 * 2, int8)
    >>> stream = BitStream()
    >>> stream.write(int8s)
    """

def read_int8_1_by_1_not_aligned():
    """
    >>> n = 44100 * 2 * 2
    >>> stream = BitStream(4 * [True])
    >>> stream.write(ones(n, dtype=int8))
    >>> stream.read(bool, 4)
    [True, True, True, True]
    >>> for i in range(n):
    ...     stream.read(int8, 1)
    """

def read_int8_1_by_1():
    """
    >>> n = 44100 * 2 * 2
    >>> stream = BitStream()
    >>> stream.write(ones(n, dtype=int8))
    >>> for i in range(n):
    ...     stream.read(int8, 1)
    """

def read_int8_2_by_2():
    """
    >>> n = 44100 * 2 * 2
    >>> stream = BitStream()
    >>> stream.write(ones(n, dtype=int8))
    >>> for i in range(n / 2):
    ...     stream.read(int8, 2)
    """

def read_int8_4_by_4():
    """
    >>> n = 44100 * 2 * 2
    >>> stream = BitStream()
    >>> stream.write(ones(n, dtype=int8))
    >>> for i in range(n / 4):
    ...     stream.read(int8, 4)
    """

def read_int8_8_by_8():
    """
    >>> n = 44100 * 2 * 2
    >>> stream = BitStream()
    >>> stream.write(ones(n, dtype=int8))
    >>> for i in range(n / 8):
    ...     stream.read(int8, 8)
    """

def read_int8_all():
    """
    >>> n = 44100 * 2 * 2
    >>> stream = BitStream()
    >>> stream.write(ones(n, dtype=int8))
    >>> stream.read(int8, n)
    """

# ------------------------------------------------------------------------------

def write_str_1_by_1_auto_type_not_aligned():
    """
    >>> n = 44100 * 2 * 2
    >>> string = n * "A"
    >>> stream = BitStream(4 * [True])
    >>> for char in string:
    ...     stream.write(char)
    """

def write_str_1_by_1_auto_type():
    """
    >>> n = 44100 * 2 * 2
    >>> string = n * "A"
    >>> stream = BitStream()
    >>> for char in string:
    ...     stream.write(char)
    """

def write_str_1_by_1_given_type():
    """
    >>> n = 44100 * 2 * 2
    >>> string = n * "A"
    >>> stream = BitStream()
    >>> for char in string:
    ...     stream.write(char, str)
    """

def write_str_1_by_1_specialized_type():
    """
    >>> n = 44100 * 2 * 2
    >>> string = n * "A"
    >>> stream = BitStream()
    >>> for char in string:
    ...     write_str(stream, char)
    """

def write_str_1_by_1_loop_only():
    """
    >>> n = 44100 * 2 * 2
    >>> string = n * "A"
    >>> stream = BitStream()
    >>> for char in string:
    ...     do_nothing()
    """

def write_str_all():
    """
    >>> n = 44100 * 2 * 2
    >>> string = n * "A"
    >>> stream = BitStream()
    >>> stream.write(string)
    """

def read_str_1_by_1_not_aligned():
    """
    >>> n = 44100 * 2 * 2
    >>> stream = BitStream(4 * [True])
    >>> stream.write(n * "A")
    >>> stream.read(bool, 4)
    [True, True, True, True]
    >>> for i in range(n):
    ...     stream.read(str, 1)
    """

def read_str_1_by_1():
    """
    >>> n = 44100 * 2 * 2
    >>> stream = BitStream(n * "A")
    >>> for i in range(n):
    ...     stream.read(str, 1)
    """

def read_str_2_by_2():
    """
    >>> n = 44100 * 2 * 2
    >>> stream = BitStream(n * "A")
    >>> for i in range(n / 2):
    ...     stream.read(str, 2)
    """

def read_str_4_by_4():
    """
    >>> n = 44100 * 2 * 2
    >>> stream = BitStream(n * "A")
    >>> for i in range(n / 4):
    ...     stream.read(str, 4)
    """

def read_str_8_by_8():
    """
    >>> n = 44100 * 2 * 2
    >>> stream = BitStream(n * "A")
    >>> for i in range(n / 8):
    ...     stream.read(str, 8)
    """

def read_str_all():
    """
    >>> n = 44100 * 2 * 2
    >>> stream = BitStream(n * "A")
    >>> stream.read(str, n)
    """

# ------------------------------------------------------------------------------

def write_uint16_1_by_1():
    """
    >>> n = 44100 * 2
    >>> stream = BitStream()
    >>> array_ = ones(n, dtype=uint16)
    >>> for i in range(n):
    ...     stream.write(array_[i], uint16)
    """

def write_uint16_all():
    """
    >>> n = 44100 * 2
    >>> stream = BitStream()
    >>> array_ = ones(n, dtype=uint16)
    >>> stream.write(array_, uint16)
    """

def read_uint16_1_by_1():
    """
    >>> n = 44100 * 2
    >>> stream = BitStream()
    >>> array_ = ones(n, dtype=uint16)
    >>> stream.write(array_, uint16)
    >>> for i in range(n):
    ...     stream.read(uint16, 1)
    """

def read_uint16_all():
    """
    >>> n = 44100 * 2
    >>> stream = BitStream()
    >>> array_ = ones(n, dtype=uint16)
    >>> stream.write(array_, uint16)
    >>> stream.read(uint16, n)
    """
# ------------------------------------------------------------------------------

def write_int16_1_by_1():
    """
    >>> n = 44100 * 2
    >>> stream = BitStream()
    >>> array_ = ones(n, dtype=int16)
    >>> for i in range(n):
    ...     stream.write(array_[i], int16)
    """

def write_int16_all():
    """
    >>> n = 44100 * 2
    >>> stream = BitStream()
    >>> array_ = ones(n, dtype=int16)
    >>> stream.write(array_, int16)
    """

def read_int16_1_by_1():
    """
    >>> n = 44100 * 2
    >>> stream = BitStream()
    >>> array_ = ones(n, dtype=int16)
    >>> stream.write(array_, int16)
    >>> for i in range(n):
    ...     stream.read(int16, 1)
    """

def read_int16_all():
    """
    >>> n = 44100 * 2
    >>> stream = BitStream()
    >>> array_ = ones(n, dtype=int16)
    >>> stream.write(array_, int16)
    >>> stream.read(int16, n)
    """

# ------------------------------------------------------------------------------

def write_uint32_1_by_1():
    """
    >>> n = 44100
    >>> stream = BitStream()
    >>> array_ = ones(n, dtype=uint32)
    >>> for i in range(n):
    ...     stream.write(array_[i], uint32)
    """

def write_uint32_all():
    """
    >>> n = 44100
    >>> stream = BitStream()
    >>> array_ = ones(n, dtype=uint32)
    >>> stream.write(array_, uint32)
    """

def read_uint32_1_by_1():
    """
    >>> n = 44100
    >>> stream = BitStream()
    >>> array_ = ones(n, dtype=uint32)
    >>> stream.write(array_, uint32)
    >>> for i in range(n):
    ...     stream.read(uint32, 1)
    """

def read_uint32_all():
    """
    >>> n = 44100
    >>> stream = BitStream()
    >>> array_ = ones(n, dtype=uint32)
    >>> stream.write(array_, uint32)
    >>> stream.read(uint32, n)
    """

# ------------------------------------------------------------------------------

def write_int32_1_by_1():
    """
    >>> n = 44100
    >>> stream = BitStream()
    >>> array_ = ones(n, dtype=int32)
    >>> for i in range(n):
    ...     stream.write(array_[i], int32)
    """

def write_int32_all():
    """
    >>> n = 44100
    >>> stream = BitStream()
    >>> array_ = ones(n, dtype=int32)
    >>> stream.write(array_, int32)
    """

def read_int32_1_by_1():
    """
    >>> n = 44100
    >>> stream = BitStream()
    >>> array_ = ones(n, dtype=int32)
    >>> stream.write(array_, int32)
    >>> for i in range(n):
    ...     stream.read(int32, 1)
    """

def read_int32_all():
    """
    >>> n = 44100
    >>> stream = BitStream()
    >>> array_ = ones(n, dtype=int32)
    >>> stream.write(array_, int32)
    >>> stream.read(int32, n)
    """

# ------------------------------------------------------------------------------

def read_float64_1_by_1():
    """
    >>> n = (44100 * 16 * 2) / 64
    >>> floats = ones(n)
    >>> stream = BitStream(floats)
    >>> for i in range(n):
    ...     _float = stream.read(float)
    """

def read_float64_1_by_1_not_aligned():
    """
    >>> n = (44100 * 16 * 2) / 64
    >>> floats = ones(n)
    >>> stream = BitStream(4*[True])
    >>> stream.write(floats)
    >>> for i in range(n):
    ...     _float = stream.read(float)
    """

def read_float64_2_by_2():
    """
    >>> n = (44100 * 16 * 2) / 64
    >>> floats = ones(n)
    >>> stream = BitStream(floats)
    >>> for i in range(n / 2):
    ...     _floats = stream.read(float, 2)
    """

def read_float64_4_by_4():
    """
    >>> n = (44100 * 16 * 2) / 64
    >>> floats = ones(n)
    >>> stream = BitStream(floats)
    >>> for i in range(n / 4):
    ...     _floats = stream.read(float, 4)
    """

def read_float64_8_by_8():
    """
    >>> n = (44100 * 16 * 2) / 64
    >>> floats = ones(n)
    >>> stream = BitStream(floats)
    >>> for i in range(n / 8):
    ...     _floats = stream.read(float, 8)
    """

def read_float64_all():
    """
    >>> n = (44100 * 16 * 2) / 64
    >>> floats = ones(n)
    >>> stream = BitStream(floats)
    >>> _floats = stream.read(float, n)
    """


def write_float64_1_by_1_auto_type_not_aligned():
    """
    >>> n = (44100 * 16 * 2) / 64
    >>> floats = ones(n)
    >>> stream = BitStream(4 * [True])
    >>> for float_ in floats:
    ...     stream.write(float_)
    """

def write_float64_1_by_1_auto_type():
    """
    >>> n = (44100 * 16 * 2) / 64
    >>> floats = ones(n)
    >>> stream = BitStream()
    >>> for float_ in floats:
    ...     stream.write(float_)
    """

def write_float64_1_by_1_loop_only():
    """
    >>> n = (44100 * 16 * 2) / 64
    >>> floats = ones(n)
    >>> stream = BitStream()
    >>> for float_ in floats:
    ...     do_nothing()
    """

def write_float64_1_by_1_given_type():
    """
    >>> n = (44100 * 16 * 2) / 64
    >>> floats = ones(n)
    >>> stream = BitStream()
    >>> for float_ in floats:
    ...     stream.write(float_, float)
    """

def write_float64_1_by_1_specialized_type():
    """
    >>> n = (44100 * 16 * 2) / 64
    >>> floats = ones(n)
    >>> stream = BitStream()
    >>> for float_ in floats:
    ...     write_float64(stream, float_)
    """

def write_float64_1_by_1_loop_only():
    """
    >>> n = (44100 * 16 * 2) / 64
    >>> floats = ones(n)
    >>> stream = BitStream()
    >>> for float_ in floats:
    ...     pass
    """

def write_float64_2_by_2_auto_type():
    """
    >>> n = (44100 * 16 * 2) / 64
    >>> floats = ones(n)
    >>> stream = BitStream()
    >>> for i in range(n / 2):
    ...     stream.write(floats[2*i:2*(i+1)])
    """

def write_float64_4_by_4_auto_type():
    """
    >>> n = (44100 * 16 * 2) / 64
    >>> floats = ones(n)
    >>> stream = BitStream()
    >>> for i in range(n / 4):
    ...     stream.write(floats[4*i:4*(i+1)])
    """

def write_float64_8_by_8_auto_type():
    """
    >>> n = (44100 * 16 * 2) / 64
    >>> floats = ones(n)
    >>> stream = BitStream()
    >>> for i in range(n / 8):
    ...     stream.write(floats[8*i:8*(i+1)])
    """

def write_float64_all_non_aligned():
    """
    >>> n = (44100 * 16 * 2) / 64
    >>> floats = ones(n)
    >>> stream = BitStream(4 * [True])
    >>> stream.write(floats)
    """

def write_float64_all():
    """
    >>> n = (44100 * 16 * 2) / 64
    >>> floats = ones(n)
    >>> stream = BitStream()
    >>> stream.write(floats)
    """
# ------------------------------------------------------------------------------

def write_uint8_1_by_1_test_array_cast():
    """
    >>> uint8s = ones(44100 * 2 * 2, uint8)
    >>> stream = BitStream()
    >>> for uint8_ in uint8s:
    ...     _ = array(uint8_, dtype=uint8, copy=False, ndmin=1)
    """

#     array = array(data, dtype=uint8, copy=False, ndmin=1)

if __name__ == "__main__":
    import docbench
    import sys
    docbench.main(filename="./benchmark.py",
                  format="text", 
                  profile=False,
                  output=sys.stdout)


