# cython: profile = True
# coding: utf-8

"""
Binary Data Toolkit

### Overview

Create a binary stream with:

    stream = BitStream()
    
Write data into the stream with:

    stream.write(data, type)

Read data from the stream with:

    data = stream.read(type, n)
 
### About Types   
    
#### Supported Types

  - `bool`,
  - `str`,
  - `uint8`, `uint16`, `uint32`, 
  - `int8`, `int16`, `int32`,
  - `float` (`float64`),
  - `bitstream`.

#### Custom Types    
    
The `type` parameter in `read` and `write` may be either a type or an instance
of a type when the codec has options.

"""

# Standard Python 2.7 Library 

# Unfortunately, this renaming of type deoptimizes its management by Cython
# (as a builtin). The alternative is to use Py_TYPE macro magic, but 
# I am unsure about reference counting (and whether the extra perf does
# justify it). And we also need 'type' (as a type) in a isinstance ...
import __builtin__
cdef object __builtin__type = __builtin__.type
import copy
import doctest
import hashlib
import struct
import sys
import timeit

# Third Party Libraries
import numpy

# Cython
cimport cython
cimport numpy as np
from libc.stdlib cimport malloc, realloc, free
from libc.string cimport memcpy
from cpython cimport bool as boolean, Py_INCREF, Py_DECREF, PyObject, PyObject_GetIter, PyErr_Clear
cdef extern from "Python.h":
    int _PyFloat_Pack8 (double, unsigned char *, int) except -1
    # PyObject* Py_TYPE(object)
#
# TODO
# ------------------------------------------------------------------------------
#
# Implement a more simpler and more easily implementable read policy: in every
# case (but for str), unless n is inf, we should read the read n as read exactly
# n values (or 1, and unboxed when n is None). When n is inf, that means read
# everything, up to the end of the stream. If each case, if it can't be achieved
# (not enough data, or reading invalid code, or can't get to the end of the
# stream for n=inf), a ReadError should be raised. 
#
# Today, there is a mix where n=None is not forgiving but n > len(data) is for
# example. That makes usage of this API a mess. Also, the "try until u can't"
# has severe issues when it comes to beginning to decode, then realizing in the
# middle that we can't anymore, because we have altered the original stream.
# So the trailing bits if any in this case are corrupted anyway ; imposing the
# end of the stream is simpler. If there was a ReadError raised, the original
# stream is considered borked, it could be corrupted (partially read).
#
# A consequence of that policy: the interpretation of a raised ReadError is
# always clear from the context: either we can't manage to read n data from
# a stream (eos or invalid coding, which is kind of equivalent: there is simply
# just not enough proper data encoded in the stream) or if n=inf, the read is
# not exact (trailing bits would be left).

# Rk: the ReadError policy has to be explained type by type with respect to
#     one characteristic: is the stream unaltered when the read fails or not ?
#     The best is NOT to give any guarantee in this respect ... Arf, unless we
#     can easily do it (?). Nah not really easily, we need to get the start 
#     offset (internal ! Can't be done from Python code ?), memorize it and 
#     rollback if there is a problem ... It can be done if I decide so, with
#     the public keyword ... That would be a nice property ... but probably
#     a performance and maintenance cost. KISS applies here.
#
#
# Update: above is partially obsolete: the snapshot effort is meant to
#         allow for all potentially stream-corruptiing operations to be
#         roll-backed, so that the mere error scheme can be converted to
#         a robust exception scheme.

#  
# TODO: Consider using the Numpy C API instead of casting with array.
#       (see <http://docs.scipy.org/doc/numpy/reference/c-api.array.html>)
#       This is actually 2/3 of the times spent in writing of ndarray-like data.
#
# TODO: get rid of inf. Semantics are unclear, use cases are poor.
#
# TODO: define pxd interface files for faster calls from Cython modules ?
#
# ------------------------------------------------------------------------------
# The attributes `_read_offset` and `_write_offset` are probably a stupid 
# way to represent the bit pointers. (I don't even know the size of `long long` is long ...). 
# I have no idea how the library behaves if we try to use it with very large (~500 Mo)
# bitstreams. We should "hit the wall" 8 times to early due to the
# offset representation.
#
# The smart/tight representation is probably a pair (byte_offset, bit offset) 
# with size_t / unsigned char types. And anyway we compute this pair over
# and over in all readers/writers, the refactored code should be as simple
# as the previous one, except for the need to have a small overflow management
# with the bit offset (something that should probably be inlined).
#

#
# Metadata
# ------------------------------------------------------------------------------
#
__author__ = u"Sébastien Boisgérault <Sebastien.Boisgerault@mines-paristech.fr>"
__license__ = "MIT License"
__version__ = "1.0.0-alpha.7"

#
# BitStream
# ------------------------------------------------------------------------------
#

cdef unsigned char *byte_array_malloc(size_t size):
    cdef unsigned char *_bytes 
    _bytes = <unsigned char *>malloc(size * sizeof(unsigned char))
    if not _bytes:
        raise MemoryError()
    else:
        return _bytes

cdef byte_array_free(unsigned char *_bytes):
    free(_bytes)

class ReadError(Exception):
    pass

class WriteError(Exception):
    pass

cdef dict _readers = {}
cdef dict _writers = {}

def register(type, reader=None, writer=None):
    if reader is not None:
        _readers[type] = reader
    if writer is not None:
        _writers[type] = writer

cdef object none = None
cdef boolean true  = True
cdef boolean false = False
cdef type uint8   = numpy.uint8
cdef type int8    = numpy.int8
cdef type uint16  = numpy.uint16
cdef type int16   = numpy.int16
cdef type uint32  = numpy.uint32
cdef type int32   = numpy.int32
cdef type uint64  = numpy.uint64
cdef type int64  = numpy.int64
cdef type float64 = numpy.float64
cdef type ndarray = numpy.ndarray
cdef object zero = 0
cdef object one  = 1

cdef class State

cdef class BitStream:
    """
    BitStream Class
    """
    cdef unsigned char *_bytes
    cdef size_t _num_bytes
    cdef unsigned long long _read_offset
    cdef unsigned long long _write_offset
    cdef list _states
    cdef unsigned int _state_id

    cdef dict readers    
    cdef dict writers
    
    def __cinit__(self):
        self._read_offset = 0
        self._write_offset = 0
        self._num_bytes = 0
        self._bytes = NULL
        self._states = [State(self, 0, 0, 0)]
        self._state_id = 0

    def __init__(self, *args, **kwargs):
        if args or kwargs:
            self.write(*args, **kwargs)

    def __len__(self):
        return self._write_offset - self._read_offset

    cpdef int _extend(self, size_t num_bits) except -1:
        """
        Make room for `num_bits` extra bits into the stream.

        Warning: a reallocation may take place and invalidate `self._bytes`.
        The attributes `_read_offset` and `_write_offset` are unchanged.
        """
        cdef long num_extra_bits
        cdef size_t num_extra_bytes, new_num_bytes        
        
        num_extra_bits = num_bits + self._write_offset - 8 * self._num_bytes
        if num_extra_bits > 0:
            num_extra_bytes = num_extra_bits / 8
            num_extra_bits  = num_extra_bits - 8 * num_extra_bytes
            new_num_bytes = self._num_bytes + num_extra_bytes + (num_extra_bits != 0)
            self._bytes = <unsigned char *>realloc(self._bytes, new_num_bytes)
            self._num_bytes = new_num_bytes
        return 0

# TODO: builtin_type prevents Cython to optimize the type function ...
#       add an underscore to "type" in the signature ? Use *args and
#       *kwargs and get the info (and validate the stuff ?). Does it
#       destroy the cases where the function could be called as a C
#       function ?
    cpdef write(self, data, type=None):
        cdef size_t length
        cdef int auto_detect = 0
        type_error = "unsupported type {0!r}."

        # type = args[0] if args else kwargs.get("type")

        # automatic type detection
        if type is None:
            auto_detect = 1
            # single bool optimization
            if data is true or data is false:
                type = bool
            else:
                data_type = __builtin__type(data)
                if data_type is list:
                    if len(data) == 0:
                        return
                    else:
                        type = __builtin__type(data[0]) # really ?                   
                elif data_type is ndarray:
                    type = data.dtype.type
                else:
                    type = data_type

        # find the appropriate writer
        if type is bool:
            write_bool(self, data)
        elif type is uint8:
            write_uint8(self, data)
        elif type is int8:
            write_int8(self, data)
        elif type is str:
            write_str(self, data)
        elif type is BitStream:
            write_bitstream(self, data)
        elif type is uint16:
            write_uint16(self, data)
        elif type is int16:
            write_int16(self, data)
        elif type is uint32:
            write_uint32(self, data)
        elif type is int32:
            write_int32(self, data)
        elif type is uint64:
            write_uint64(self, data)
        elif type is int64:
            write_int64(self, data)
        elif type is float or type is float64:
            write_float64(self, data)
        # fallback to the writers dictionary
        elif auto_detect or isinstance(type, __builtin__type):
            writer = _writers.get(type)
            if writer is None:
                raise TypeError(type_error.format(type.__name__))
            writer(self, data)
        # lookup for a writer *factory*
        else: 
            instance = type
            type = __builtin__type(instance)
            writer_factory = _writers.get(type)
            if writer_factory is None:
                raise TypeError(type_error.format(type.__name__))
            else:
                writer = writer_factory(instance)
            writer(self, data)

    cpdef read(self, type=None, n=None): 
        if (type is None or isinstance(type, int)) and n is None:
            n = type
            type = BitStream

        # find the appropriate reader
        if type is bool:
            return read_bool(self, n)
        elif type is uint8:
            return read_uint8(self, n)
        elif type is int8:
            return read_int8(self, n)
        elif type is str:
            return read_str(self, n)
        elif type is BitStream:
            return read_bitstream(self, n)
        elif type is uint16:
            return read_uint16(self, n)
        elif type is int16:
            return read_int16(self, n)
        elif type is uint32:
            return read_uint32(self, n)
        elif type is int32:
            return read_int32(self, n)
        elif type is uint64:
            return read_uint64(self, n)
        elif type is int64:
            return read_int64(self, n)
        elif type is float or type is float64:
            return read_float64(self, n)
        # fallback to the readers dictionary
        elif isinstance(type, __builtin__type):
            reader = _readers.get(type)
            if reader:
                return reader(self, n)
            else:
                raise TypeError("unsupported type {0!r}.".format(type.__name__))
        else: # lookup for a reader *factory*
            instance = type
            type = __builtin__type(instance)
            reader_factory = _readers.get(type)
            if reader_factory is None:
                raise TypeError("unsupported type {0!r}.".format(type.__name__))
            else:
                reader = reader_factory(instance)
                return reader(self, n)

    def __str__(self):
        bools = []
        len_ = self._write_offset - self._read_offset
        for i in range(len_):
            byte_index, bit_index = divmod(self._read_offset + i, 8)
            mask = 128 >> bit_index
            bools.append(bool(self._bytes[byte_index] & mask))
        return "".join([str(int(bool_)) for bool_ in bools])

    cpdef copy(self, n=None):
        cdef unsigned long long read_offset = self._read_offset
        copy = read_bitstream(self, n)
        self._read_offset = read_offset
        return copy

    def __copy__(self):
        return self.copy()
    
    def __deepcopy__(self, memo):
        return self.copy()
        
    def __repr__(self):
        return str(self)

    def __hash__(self):
        copy = self.copy() # read_only would be better
        uint8s = copy.read(numpy.uint8, len(self) / 8)
        bools  = copy.read(bool, len(copy))
        return hash((hashlib.sha1(uint8s).hexdigest(), tuple(bools)))

    def __richcmp__(self, other, int operation):
        # see http://docs.cython.org/src/userguide/special_methods.html
        cdef boolean equal
        if operation not in (2, 3):
            raise NotImplementedError()
        s1 = self.copy() # read_only would be better ...
        s2 = other.copy() # test for type, 
        equal = all(s1.read(numpy.uint8, len(s1) / 8) == s2.read(numpy.uint8, len(s2) / 8)) and\
                (s1.read(bool, len(s1)) == s2.read(bool, len(s2)))
        if operation == 2:
            return equal
        else:
            return not equal

    cdef State save(self):
        cdef State state
        state = self._states[-1]
        if state._read_offset != self._read_offset or \
           state._write_offset != self._write_offset:
            self._state_id = self._state_id + 1
            # BUG: cython -a displays this line as not optimized ...
            # is it because `State` is not recognized as an extension type ?
            # We have a general PyObjectCall going on here, even if I 
            # declare save as C-only. Should I / can I use a struct instead ?
            state = State(self, self._read_offset, self._write_offset, self._state_id)
            self._states.append(state)
        return state

    cpdef restore(self, State state):
        if self != state._stream:
            raise ValueError("the state does not belong to this stream.")
        # The restore action may fail, so we work on a copy of the saved states.
        states = copy.copy(self._states)
        while states:
            if state == <State>states[-1]:
                self._read_offset  = state._read_offset
                self._write_offset = state._write_offset
                self._states = states
                break
            else:
                states.pop()
        else:
            raise ValueError("this state is not saved in the stream.")

    def __dealloc__(self):
        free(self._bytes)

#
# Bitstream State
# ------------------------------------------------------------------------------
#

cdef class State: # meant to be opaque and immutable.
    cdef readonly BitStream _stream
    cdef readonly unsigned long long _read_offset
    cdef readonly unsigned long long _write_offset
    cdef readonly unsigned int _id

    def __cinit__(self, BitStream stream, 
                        unsigned long long _read_offset, 
                        unsigned long long _write_offset, 
                        unsigned int _id):
        self._stream = stream
        self._read_offset = _read_offset
        self._write_offset = _write_offset
        self._id = _id

# TODO: hash

    def __richcmp__(self, State other, int operation):
        # see http://docs.cython.org/src/userguide/special_methods.html
        cdef boolean equal
        if operation not in (2, 3):
            raise NotImplementedError()
        # BUG: the state attribute access is not optimized ... Why ?
        equal = self._stream == other._stream and \
                self._read_offset == other._read_offset and \
                self._write_offset == other._write_offset and \
                self._id == other._id
        if operation == 2:
            return equal
        else:
            return not equal
#
# Bool Reader / Writer
# ------------------------------------------------------------------------------
#

cpdef read_bool(BitStream stream, n=None):
    """
    Read bools from a stream.
    """
    cdef unsigned char *_bytes
    cdef unsigned char mask
    cdef unsigned long i, _n
    cdef size_t byte_index
    cdef unsigned char bit_index
    
    _bytes = stream._bytes
    if n is None: # read a single bool.
        if len(stream) == 0:
            raise ReadError("end of the stream")
        byte_index = stream._read_offset / 8
        bit_index  = stream._read_offset - 8 * byte_index
        mask = 128 >> bit_index
        stream._read_offset += 1
        return bool(_bytes[byte_index] & mask)

    if n > len(stream):
        raise ReadError("end of the stream")
    else:
        _n = n

    bools = _n * [False]
    for i in range(_n):
        byte_index = (stream._read_offset + i ) / 8
        bit_index  = (stream._read_offset + i ) - 8 * byte_index            
        mask = 128 >> bit_index
        bools[i] = bool(_bytes[byte_index] & mask)
    stream._read_offset += _n
    return bools

# TODO: support numpy._bool (that are not singletons) and arrays.
#       Consistency with the array implementation and the way we
#       handle list also dictates that in last resolt, we cast the
#       argument to bool and write it.
# TODO: lots of code duplicate. Consider an C inline function and
#       measure the impact.
cpdef write_bool(BitStream stream, bools):
    """
    Write bools into a stream.
    """
    cdef unsigned char *_bytes
    cdef unsigned char _byte
    cdef unsigned char mask1, mask2, mask
    cdef unsigned long long i, n
    cdef size_t byte_index
    cdef unsigned char bit_index
    cdef long long offset
    #cdef boolean _bool
    cdef list _bools
    cdef type _type
    cdef np.uint8_t _np_bool
    #cdef np.ndarray[np.uint8_t, ndim=1, cast=True] _array

    offset = stream._write_offset
    # Rk: the fallback path is actually only 7% slower than the "fast" path.
    #     It is worth keeping the duplicated code here ?
    if bools is false or bools is zero: # False or 0 (if cached).
        stream._extend(1)
        _bytes = stream._bytes
        byte_index = offset / 8
        bit_index  = offset - 8 * byte_index
        mask1 = 128 >> bit_index
        mask2 = 255 - mask1
        _bytes[byte_index] = (_bytes[byte_index] & mask2)
        stream._write_offset += 1
    elif bools is true or bools is one: # True or 1 (if cached).
        stream._extend(1)
        _bytes = stream._bytes
        byte_index = offset / 8
        bit_index  = offset - 8 * byte_index
        mask1 = 128 >> bit_index
        mask2 = 255 - mask1
        _bytes[byte_index] = (_bytes[byte_index] & mask2) | mask1
        stream._write_offset += 1
    else:
        _type = type(bools)
        if _type is list:
            _bools = bools
            n = len(_bools)
            stream._extend(n)
            _bytes = stream._bytes
            i = 0
            for _bool in _bools: # faster than a loop on i
                byte_index = (offset + i) / 8
                bit_index  = (offset + i) - 8 * byte_index
                mask1 = 128 >> bit_index
                mask2 = 255 - mask1
                _byte = _bytes[byte_index]
                if _bool is false: # check the benefit of duplication here ?
                    _bytes[byte_index] = (_byte & mask2)
                elif _bool is true or _bool:
                    _bytes[byte_index] = (_byte & mask2) | mask1
                else:
                    _bytes[byte_index] = (_byte & mask2)
                i += 1
            stream._write_offset += n
        elif _type is ndarray:
            # Perf is not very good here for small sizes: 25% RT for 8-bit 
            # chunks (compared with 5% for lists of bools). Even for large
            # size, the array is not much faster ...
            # Plus the semantics is a mess: BitStream(array(256, uint16), bool)
            # would yield 0 for example, instead of 1.
            # try with dtype=bool again and go beyond the ValueError ?
            # OK, done with "cast=True", that semantics issue is solved.
            # TODO: Add tests to make sure that part works as expected.
            # Can't do much for the dog slow part ... this is the array
            # cast mostly (~ 2/3 of the time) ...
            # Today we pay the cost even if the array needs no cast
            # (right type, right dimension ...)
            # Note that if the type does not match (say uint8), we
            # go up to 45% RT ...
            # I guess that for bools I may have to kill this call to array ...
            # and iterate directly on the structure ? Try that ? May slightly
            # deoptimize the list code and share this code ?
            # Well if we do that, the array code is "only" 17% of RT (25% for
            # non-bool types) and typically always stay 2x slower than the
            # list case (3x for non-bool types). And the check that still 
            # lack are going to slow down the things a little ...

            # TODO: need to check dimensions ... Maybe we should not accept
            #       0-dim arrays to begin with ? And let the 2-dim and more
            #       array pass as if the value to be cast to bool is the 
            #       inner array (this is gonna generate a ValueError that
            #       may be quite cryptic ...)
            #       We could do that ... but the behavior will (slightly
            #       differ from the other writers if we don't accept 0-dim
            #       arrays). So add the support for them. (is there a macro
            #       from the Numpy API that we could use ? I think so.)
            n = len(bools)
            stream._extend(n)
            _bytes = stream._bytes
            i = 0
            for _bool in bools:
                byte_index = (offset + i) / 8
                bit_index  = (offset + i) - 8 * byte_index
                mask1 = 128 >> bit_index
                mask2 = 255 - mask1
                _byte = _bytes[byte_index]
                if _bool:
                    _bytes[byte_index] = (_byte & mask2) | mask1
                else:
                    _bytes[byte_index] = (_byte & mask2)
                i += 1
            stream._write_offset += n

#            _array = numpy.array(bools, dtype=bool, ndmin=1, copy=False)
#            n = len(_array)
#            stream._extend(n)
#            _bytes = stream._bytes
#            i = 0
#            for i in range(n):
#                _np_bool = <np.uint8_t>(_array[i])
#                byte_index = (offset + i) / 8
#                bit_index  = (offset + i) - 8 * byte_index
#                mask1 = 128 >> bit_index
#                mask2 = 255 - mask1
#                _byte = _bytes[byte_index]
#                if _np_bool:
#                    _bytes[byte_index] = (_byte & mask2) | mask1
#                else:
#                    _bytes[byte_index] = (_byte & mask2)
#                i += 1
#            stream._write_offset += n
        elif bools:
            stream._extend(1)
            _bytes = stream._bytes
            byte_index = offset / 8
            bit_index  = offset - 8 * byte_index
            mask1 = 128 >> bit_index
            mask2 = 255 - mask1
            _bytes[byte_index] = (_bytes[byte_index] & mask2) | mask1
            stream._write_offset += 1
        else:
            stream._extend(1)
            _bytes = stream._bytes
            byte_index = offset / 8
            bit_index  = offset - 8 * byte_index
            mask1 = 128 >> bit_index
            mask2 = 255 - mask1
            _bytes[byte_index] = (_bytes[byte_index] & mask2)
            stream._write_offset += 1

register(bool, reader=read_bool, writer=write_bool)
register(numpy.bool_, reader=read_bool, writer=write_bool)

#
# Integers Type Readers and Writers: signed/unsigned, 8/16/32 bits integers
# ------------------------------------------------------------------------------
#

# TODO: check type, if that's not ndarray / list, treat as a scalar. (fast path)
#       otherwise cast to array, this policy has the best asymptotic behavior
#       and perform the type check upfront for list that may contain stuff that
#       can't be converted to uint8.
cpdef write_uint8(BitStream stream, data):
    cdef unsigned char *_bytes
    cdef size_t num_bytes, byte_index, i
    cdef unsigned char bit_index, bit_index_c
    cdef unsigned char mask1, mask2, _uint8
    cdef type _type, _dtype
    cdef object iterator
    cdef int iterable
    cdef unsigned char _byte
    cdef np.ndarray[np.uint8_t, ndim=1] array
    cdef np.uint8_t uint8_

    byte_index = stream._write_offset / 8
    bit_index  = stream._write_offset - 8 * byte_index
    bit_index_c = 8 - bit_index
    mask2 = 255 >> bit_index
    mask1 = 255 - mask2
    
    _type = type(data)
    
    if _type is list or _type is np.ndarray: 
        # don't "cast" if this is an array ? measure list / array perf.
        # discrepancy in benchmarks ?
        array = numpy.array(data, dtype=uint8, copy=False, ndmin=1)
        num_bytes = len(array)
        stream._extend(8 * num_bytes)
        _bytes = stream._bytes
        i = 0
        if bit_index == 0:
            for i in range(num_bytes):
                _bytes[byte_index + i] = <unsigned char>(array[i])
        else:
            for i in range(num_bytes):
                uint8_ = <unsigned char>(array[i])
                _byte = (<unsigned char>uint8_) >> bit_index
                _bytes[byte_index + i] = (_bytes[byte_index + i] & mask1) | _byte
                _byte = ((<unsigned char>uint8_) << bit_index_c) & 255
                _bytes[byte_index + i + 1]  = \
                    (_bytes[byte_index + i + 1] & mask2) | _byte
        stream._write_offset += 8 * num_bytes
    else: # if data is not a list or an array, it should be an scalar.
        stream._extend(8)
        _bytes = stream._bytes
        if _type is uint8:
            _byte = <unsigned char>(data)
        else:
            _byte = uint8(data)
        if bit_index == 0:
            _bytes[byte_index] = _byte
        else:
            _uint8 = _byte >> bit_index
            _bytes[byte_index] = (_bytes[byte_index] & mask1) | _uint8
            _uint8 = (_byte << bit_index_c) & 255
            _bytes[byte_index + 1]  = \
                (_bytes[byte_index + 1] & mask2) | _uint8
        stream._write_offset += 8           
     
#cpdef ____write_uint8(BitStream stream, data):
#    """
#    Write unsigned 8-bit integers into a stream.
#    """
#    array = numpy.array(data, uint8, copy=false, ndmin=1)
#    _write_uint8(stream, array)

@cython.boundscheck(False) # TODO: generalize
cpdef _write_uint8(BitStream stream, np.ndarray[np.uint8_t, ndim=1] uint8s):
    """
    Write a 1-dim. array of unsigned 8-bit integers into a stream.
    """
    cdef unsigned char *_bytes
    cdef size_t num_bytes, byte_index, i
    cdef unsigned char bit_index, bit_index_c
    cdef unsigned char mask1, mask2, _uint8
          
    num_bytes = len(uint8s)
    stream._extend(8 * num_bytes)
    _bytes = stream._bytes        
    
    byte_index = stream._write_offset / 8
    bit_index  = stream._write_offset - 8 * byte_index
    bit_index_c = 8 - bit_index

    mask2 = 255 >> bit_index
    mask1 = 255 - mask2
    
    if bit_index == 0:
        for i in range(num_bytes):
            _bytes[byte_index + i] = <unsigned char>uint8s[i]
    else:
        for i in range(num_bytes):
            _uint8 = (<unsigned char>uint8s[i]) >> bit_index
            _bytes[byte_index + i] = (_bytes[byte_index + i] & mask1) | _uint8
            _uint8 = ((<unsigned char>uint8s[i]) << bit_index_c) & 255
            _bytes[byte_index + i + 1]  = \
                (_bytes[byte_index + i + 1] & mask2) | _uint8            
    stream._write_offset += 8 * num_bytes         
     
cpdef read_uint8(BitStream stream, n=None):
    """
    Read unsigned 8-bit integers from a stream.
    """
    cdef unsigned char* _bytes
    cdef size_t i, byte_index
    cdef unsigned char bit_index, bit_index_c
    cdef unsigned char mask1, mask2
    cdef unsigned char _byte
    cdef size_t num_bytes
    cdef np.ndarray[np.uint8_t, ndim=1] uint8s

    _bytes = stream._bytes
    byte_index = stream._read_offset / 8
    bit_index  = stream._read_offset - 8 * byte_index
    bit_index_c = 8 - bit_index
    
    if n is None:
        if len(stream) < 8:
            raise ReadError("end of stream")
        stream._read_offset += 8
        if bit_index == 0:
            return uint8(_bytes[byte_index]) # cast instead ? probably faster.
        else:
          bit_index_c = 8 - bit_index
          mask1 = 255 >> bit_index
          mask2 = 255 - mask1
          _byte = ((_bytes[byte_index    ] & mask1) << bit_index) + \
                  ((_bytes[byte_index + 1] & mask2) >> bit_index_c)         
          return uint8(_byte)
    
    if len(stream) < 8 * n:
        raise ReadError("end of stream")
    num_bytes = min(n, len(stream) / 8)
    uint8s = numpy.zeros(num_bytes, dtype=uint8)
    if bit_index == 0:
        for i in range(num_bytes):
            uint8s[i] = _bytes[byte_index + i]
    else:
        mask1 = 255 >> bit_index
        mask2 = 255 - mask1
        for i in range(num_bytes):
            _byte = ((_bytes[byte_index + i  ] & mask1) << bit_index) + \
                    ((_bytes[byte_index + i+1] & mask2) >> bit_index_c)
            uint8s[i] = _byte
    stream._read_offset += 8 * num_bytes
    return uint8s
    
register(uint8, reader=read_uint8, writer=write_uint8)

cpdef write_int8(BitStream stream, data):
    """
    Write signed 8-bit integers into a stream.
    """
    array = numpy.array(data, dtype=int8, copy=False, ndmin=1)
    _write_int8(stream, array)

cpdef _write_int8(BitStream stream, np.ndarray[np.int8_t, ndim=1] int8s):
    """
    Write a 1-dim. array of signed 8-bit integers into a stream.
    """
    cdef unsigned char *_bytes
    cdef size_t num_bytes, byte_index, i
    cdef unsigned char bit_index, bit_index_c
    cdef unsigned char mask1, mask2, int8

    num_bytes = len(int8s)
    stream._extend(8 * num_bytes)
    _bytes = stream._bytes

    byte_index = stream._write_offset / 8
    bit_index  = stream._write_offset - 8 * byte_index
    bit_index_c = 8 - bit_index

    mask2 = 255 >> bit_index
    mask1 = 255 - mask2
    
    if bit_index == 0:
        for i in range(num_bytes):
            _bytes[byte_index + i] = <unsigned char>int8s[i]
    else:
        for i in range(num_bytes):
            int8 = (<unsigned char>int8s[i]) >> bit_index
            _bytes[byte_index + i] = (_bytes[byte_index + i] & mask1) | int8
            int8 = ((<unsigned char>int8s[i]) << bit_index_c) & 255
            _bytes[byte_index + i + 1]  = \
                (_bytes[byte_index + i + 1] & mask2) | int8            
    stream._write_offset += 8 * num_bytes

cpdef read_int8(BitStream stream, n=None):
    """
    Read signed 8-bit integers from a stream.
    """
    return read_uint8(stream, n).astype("int8")

register(numpy.int8, reader=read_int8, writer=write_int8)

cpdef read_uint16(BitStream stream, n=None):
    """
    Read unsigned 16-bit integers from a stream.
    """
    cdef unsigned char* _bytes
    cdef size_t byte_index
    cdef unsigned long bit_length, 
    cdef unsigned char bit_index, bit_index_c
    cdef unsigned char mask1, mask2
    cdef unsigned int _uint16
    cdef size_t i
    cdef size_t num_uint16s

    _bytes = stream._bytes        
    byte_index = stream._read_offset / 8
    bit_index  = stream._read_offset - 8 * byte_index
    
    if n is None:
        if len(stream) < 16:
            raise ReadError("end of stream")
        stream._read_offset += 16
        if bit_index == 0:
            _uint16 = (_bytes[byte_index] << 8) + _bytes[byte_index + 1]
            return uint16(_uint16)
        else:
            bit_index_c = 8 - bit_index
            mask1 = 255 >> bit_index
            mask2 = 255 - mask1
            _uint16 = ((_bytes[byte_index    ] & mask1) << bit_index) + \
                      ((_bytes[byte_index + 1] & mask2) >> bit_index_c)  
            _uint16 = _uint16 << 8
            _uint16 += ((_bytes[byte_index + 1] & mask1) << bit_index) + \
                      ((_bytes[byte_index + 2] & mask2) >> bit_index_c)
            return uint16(_uint16)

    if len(stream) < 16 * n:
        raise ReadError("end of stream")

    num_uint16s = min(n, len(stream) / 16)
    uint16s = numpy.zeros(num_uint16s, dtype=uint16)
    if bit_index == 0:
        for i in range(num_uint16s):
            _uint16 = (_bytes[byte_index + 2 * i    ] << 8) + \
                       _bytes[byte_index + 2 * i + 1]
            uint16s[i] = _uint16
    else:
        bit_index_c = 8 - bit_index
        mask1 = 255 >> bit_index
        mask2 = 255 - mask1
        for i in range(num_uint16s):
            _uint16 = ((_bytes[byte_index + 2*i  ] & mask1) << bit_index) + \
                      ((_bytes[byte_index + 2*i+1] & mask2) >> bit_index_c) 
            _uint16 = _uint16 << 8
            _uint16 += ((_bytes[byte_index + 2*i+1] & mask1) << bit_index) + \
                       ((_bytes[byte_index + 2*i+2] & mask2) >> bit_index_c)
            uint16s[i] = _uint16
    stream._read_offset += 16 * num_uint16s
    return uint16s
    
cpdef write_uint16(BitStream stream, data):
    """
    Write unsigned 16-bit integers into a stream.
    """
    array = numpy.array(data, uint16, copy=false, ndmin=1)
    _write_uint16(stream, array)

cpdef _write_uint16(BitStream stream, np.ndarray[np.uint16_t, ndim=1] uint16s):
    """
    Write a 1-dim. array of unsigned 16-bit integers into a stream.
    """
    cdef unsigned char* _bytes
    cdef size_t i, num_uint16s, byte_index
    cdef unsigned long bit_length, bit_index, bit_index_c
    cdef unsigned char mask1, mask2, base, byte
                            
    num_uint16s = len(uint16s)
    stream._extend(16 * num_uint16s)
    _bytes = stream._bytes # That's a nasty bug if i take a ref to _bytes
    # BEFORE the extend ...

    byte_index = stream._write_offset / 8
    bit_index  = stream._write_offset - 8 * byte_index
    bit_index_c = 8 - bit_index

    mask2 = 255 >> bit_index
    mask1 = 255 - mask2
   
    if bit_index == 0:
        for i in range(num_uint16s):
            _bytes[byte_index + 2*i]   = <unsigned char>(uint16s[i] >>  8)
            _bytes[byte_index + 2*i+1] = <unsigned char>(uint16s[i] & 255)
    else:
        for i in range(num_uint16s):
            base = uint16s[i] >> 8
            byte = (<unsigned char>base) >> bit_index
            _bytes[byte_index + 2*i] = \
                (_bytes[byte_index + 2*i] & mask1) | byte
            byte = ((<unsigned char>base) << bit_index_c) & 255
            base = uint16s[i] & 255
            _bytes[byte_index + 2*i+1] = \
                (_bytes[byte_index + 2*i+1] & mask2) | byte   
            byte = (<unsigned char>base) >> bit_index
            _bytes[byte_index + 2*i+1] = \
                (_bytes[byte_index + 2*i+1] & mask1) | byte
            byte = ((<unsigned char>base) << bit_index_c) & 255
            _bytes[byte_index + 2*i+2] = \
                (_bytes[byte_index + 2*i+2] & mask2) | byte                   
    stream._write_offset += 16 * num_uint16s    
    
register(uint16, reader=read_uint16, writer=write_uint16)

cpdef read_int16(BitStream stream, n=None):
    """
    Read signed 16-bit integers from a stream.
    """
    return stream.read(numpy.uint16, n).astype("int16")

cpdef write_int16(BitStream stream, data):
    """
    Write signed 16-bit integers into a stream.
    """
    array = numpy.array(data, int16, copy=false, ndmin=1)
    _write_int16(stream, array)

cpdef _write_int16(BitStream stream, np.ndarray[np.int16_t, ndim=1] int16s):
    """
    Write a 1-dim. array of signed 16-bit integers into a stream.
    """
    cdef unsigned char* _bytes
    cdef size_t i, num_int16s, byte_index
    cdef unsigned long bit_length, bit_index, bit_index_c
    cdef unsigned char mask1, mask2, base, byte
                            
    num_int16s = len(int16s)
    stream._extend(16 * num_int16s)
    _bytes = stream._bytes

    byte_index = stream._write_offset / 8
    bit_index  = stream._write_offset - 8 * byte_index
    bit_index_c = 8 - bit_index

    mask2 = 255 >> bit_index
    mask1 = 255 - mask2
    
    if bit_index == 0:
        for i in range(num_int16s):
            _bytes[byte_index + 2*i]   = <unsigned char>(int16s[i] >>  8)
            _bytes[byte_index + 2*i+1] = <unsigned char>(int16s[i] & 255)               
    else:
        for i in range(num_int16s):
            base = int16s[i] >> 8
            byte = (<unsigned char>base) >> bit_index
            _bytes[byte_index + 2*i] = \
                (_bytes[byte_index + 2*i] & mask1) | byte
            byte = ((<unsigned char>base) << bit_index_c) & 255
            base = int16s[i] & 255
            _bytes[byte_index + 2*i+1] = \
                (_bytes[byte_index + 2*i+1] & mask2) | byte   
            byte = (<unsigned char>base) >> bit_index
            _bytes[byte_index + 2*i+1] = \
                (_bytes[byte_index + 2*i+1] & mask1) | byte
            byte = ((<unsigned char>base) << bit_index_c) & 255
            _bytes[byte_index + 2*i+2] = \
                (_bytes[byte_index + 2*i+2] & mask2) | byte                   
    stream._write_offset += 16 * num_int16s

register(numpy.int16, reader=read_int16, writer=write_int16)

cpdef read_uint32(BitStream stream, n=None):
    """
    Read unsigned 32-bit integers from a stream.
    """
    cdef unsigned char* _bytes
    cdef size_t byte_index
    cdef unsigned long bit_length, 
    cdef unsigned char bit_index, bit_index_c
    cdef unsigned char mask1, mask2
    cdef unsigned long uint32
    cdef size_t i
    cdef unsigned char s
    cdef size_t num_uint32s

    _bytes = stream._bytes
    byte_index = stream._read_offset / 8
    bit_index  = stream._read_offset - 8 * byte_index
    
    if n is None:
        if len(stream) < 32:
            raise ReadError("end of stream")
        stream._read_offset += 32
        if bit_index == 0:
            uint32 = (_bytes[byte_index    ] << 24) + \
                     (_bytes[byte_index + 1] << 16) + \
                     (_bytes[byte_index + 2] <<  8) + \
                     (_bytes[byte_index + 3]      )
            return numpy.uint32(uint32)
        else:
            bit_index_c = 8 - bit_index
            mask1 = 255 >> bit_index
            mask2 = 255 - mask1
            uint32 = 0
            for s in range(4):
                uint32 = uint32 << 8
                uint32 += ((_bytes[byte_index + s    ] & mask1) << bit_index) + \
                          ((_bytes[byte_index + s + 1] & mask2) >> bit_index_c)
            return numpy.uint32(uint32)

    if len(stream) < 32 * n:
        raise ReadError("end of stream")

    num_uint32s = min(n, len(stream) / 32)
    uint32s = numpy.zeros(num_uint32s, dtype=numpy.uint32)
    if bit_index == 0:
        for i in range(num_uint32s):
            uint32 = (<unsigned long>(_bytes[byte_index + 4*i  ]) << 24) + \
                     (<unsigned long>(_bytes[byte_index + 4*i+1]) << 16) + \
                     (<unsigned long>(_bytes[byte_index + 4*i+2]) <<  8) + \
                     (<unsigned long>(_bytes[byte_index + 4*i+3])      )
            uint32s[i] = uint32
    else:
        bit_index_c = 8 - bit_index
        mask1 = 255 >> bit_index
        mask2 = 255 - mask1
        for i in range(num_uint32s):
            uint32 = 0
            for s in range(4):
                uint32 = uint32 << 8
                uint32 = ((_bytes[byte_index + 4*i+s  ] & mask1) << bit_index) + \
                         ((_bytes[byte_index + 4*i+s+1] & mask2) >> bit_index_c)
            uint32s[i] = uint32
    stream._read_offset += 32 * num_uint32s
    return uint32s

cpdef write_uint32(BitStream stream, data):
    """
    Write unsigned 32-bit integers into a stream.
    """
    array = numpy.array(data, uint32, copy=false, ndmin=1)
    _write_uint32(stream, array)

cpdef _write_uint32(BitStream stream, np.ndarray[np.uint32_t, ndim=1] uint32s):
    """
    Write a 1-dim. arrray of unsigned 32-bit integers into a stream.
    """
    cdef unsigned char* _bytes
    cdef size_t i, num_uint32s, byte_index
    cdef unsigned long bit_length, bit_index, bit_index_c
    cdef unsigned char mask1, mask2, base, byte
                            
    num_uint32s = len(uint32s)
    stream._extend(32 * num_uint32s)
    _bytes = stream._bytes

    byte_index = stream._write_offset / 8
    bit_index  = stream._write_offset - 8 * byte_index
    bit_index_c = 8 - bit_index

    mask2 = 255 >> bit_index
    mask1 = 255 - mask2
    
    if bit_index == 0:
        for i in range(num_uint32s):
            _bytes[byte_index + 4*i  ] = <unsigned char>((uint32s[i] >> 24)      )
            _bytes[byte_index + 4*i+1] = <unsigned char>((uint32s[i] >> 16) & 255)
            _bytes[byte_index + 4*i+2] = <unsigned char>((uint32s[i] >>  8) & 255)
            _bytes[byte_index + 4*i+3] = <unsigned char>((uint32s[i]      ) & 255)
    else:
        for i in range(num_uint32s):
            for s in range(4):
                base = uint32s[i] >> (8 * (3 - s))                    
                byte = (<unsigned char>base) >> bit_index
                _bytes[byte_index + 4*i+s] = \
                  (_bytes[byte_index + 4*i+s] & mask1) | byte
                byte = ((<unsigned char>base) << bit_index) & 255
                _bytes[byte_index + 4*i+s+1] = \
                  (_bytes[byte_index + 4*i+s+1] & mask2) | byte
    stream._write_offset += 32 * num_uint32s

register(uint32, reader=read_uint32, writer=write_uint32)

cpdef read_int32(BitStream stream, n=None):
    """
    Read signed 32-bit integers from a stream.
    """
    return read_uint32(stream, n).astype("int32")

cpdef write_int32(BitStream stream, data):
    """
    Write signed 32-bit integers into a stream.
    """
    array = numpy.array(data, int32, copy=false, ndmin=1)
    _write_int32(stream, array)

cpdef _write_int32(BitStream stream, np.ndarray[np.int32_t, ndim=1] int32s):
    """
    Write a 1-dim. arrray of signed 32-bit integers into a stream.
    """
    cdef unsigned char* _bytes
    cdef size_t i, num_int32s, byte_index
    cdef unsigned long bit_length, bit_index, bit_index_c
    cdef unsigned char mask1, mask2, base, byte
                            
    num_int32s = len(int32s)
    stream._extend(32 * num_int32s)
    _bytes = stream._bytes

    byte_index = stream._write_offset / 8
    bit_index  = stream._write_offset - 8 * byte_index
    bit_index_c = 8 - bit_index

    mask2 = 255 >> bit_index
    mask1 = 255 - mask2
    
    if bit_index == 0:
        for i in range(num_int32s):
            _bytes[byte_index + 2*i  ] = <unsigned char>((int32s[i] >> 24)      )
            _bytes[byte_index + 2*i+1] = <unsigned char>((int32s[i] >> 16) & 255)
            _bytes[byte_index + 2*i+2] = <unsigned char>((int32s[i] >>  8) & 255)
            _bytes[byte_index + 2*i+3] = <unsigned char>((int32s[i]      ) & 255)
    else:
        for i in range(num_int32s):
            for s in range(4):
                base = int32s[i] >> (8 * (3 - s))                    
                byte = (<unsigned char>base) >> bit_index
                _bytes[byte_index + 4*i+s] = \
                  (_bytes[byte_index + 4*i+s] & mask1) | byte
                byte = ((<unsigned char>base) << bit_index) & 255
                _bytes[byte_index + 4*i+s+1] = \
                  (_bytes[byte_index + 4*i+s+1] & mask2) | byte
    stream._write_offset += 32 * num_int32s

register(int32, reader=read_int32, writer=write_int32)

cpdef read_uint64(BitStream stream, n=None):
    """
    Read unsigned 32-bit integers from a stream.
    """
    cdef unsigned char* _bytes
    cdef size_t byte_index
    cdef unsigned long bit_length, 
    cdef unsigned char bit_index, bit_index_c
    cdef unsigned char mask1, mask2
    cdef unsigned long long uint64
    cdef size_t i
    cdef unsigned char s
    cdef size_t num_uint64s

    _bytes = stream._bytes
    byte_index = stream._read_offset / 8
    bit_index  = stream._read_offset - 8 * byte_index
    
    if n is None:
        if len(stream) < 64:
            raise ReadError("end of stream")
        stream._read_offset += 64
        if bit_index == 0:
            uint64 = (<unsigned long long>(_bytes[byte_index    ]) << 56) + \
                     (<unsigned long long>(_bytes[byte_index + 1]) << 48) + \
                     (<unsigned long long>(_bytes[byte_index + 2]) << 40) + \
                     (<unsigned long long>(_bytes[byte_index + 3]) << 32) + \
                     (<unsigned long long>(_bytes[byte_index + 4]) << 24) + \
                     (<unsigned long long>(_bytes[byte_index + 5]) << 16) + \
                     (<unsigned long long>(_bytes[byte_index + 6]) <<  8) + \
                     (<unsigned long long>(_bytes[byte_index + 7])      )
            return numpy.uint64(uint64)
        else:
            bit_index_c = 8 - bit_index
            mask1 = 255 >> bit_index
            mask2 = 255 - mask1
            uint64 = 0
            for s in range(8):
                uint64 = uint64 << 8
                uint64 += ((_bytes[byte_index + s    ] & mask1) << bit_index) + \
                          ((_bytes[byte_index + s + 1] & mask2) >> bit_index_c)
            return numpy.uint64(uint64)

    if len(stream) < 64 * n:
        raise ReadError("end of stream")

    num_uint64s = min(n, len(stream) / 64)
    uint64s = numpy.zeros(num_uint64s, dtype=numpy.uint64)
    if bit_index == 0:
        for i in range(num_uint64s):
            uint64 = (_bytes[byte_index + 8*i  ] << 56) + \
                     (_bytes[byte_index + 8*i+1] << 48) + \
                     (_bytes[byte_index + 8*i+2] << 40) + \
                     (_bytes[byte_index + 8*i+3] << 32) + \
                     (_bytes[byte_index + 8*i+4] << 24) + \
                     (_bytes[byte_index + 8*i+5] << 16) + \
                     (_bytes[byte_index + 8*i+6] <<  8) + \
                     (_bytes[byte_index + 8*i+7]      )
            uint64s[i] = uint64
    else:
        bit_index_c = 8 - bit_index
        mask1 = 255 >> bit_index
        mask2 = 255 - mask1
        for i in range(num_uint64s):
            uint64 = 0
            for s in range(8):
                uint64 = uint64 << 8
                uint64 = ((_bytes[byte_index + 8*i+s  ] & mask1) << bit_index  ) + \
                         ((_bytes[byte_index + 8*i+s+1] & mask2) >> bit_index_c)
            uint64s[i] = uint64
    stream._read_offset += 64 * num_uint64s
    return uint64s

cpdef write_uint64(BitStream stream, data):
    """
    Write unsigned 64-bit integers into a stream.
    """
    array = numpy.array(data, uint64, copy=false, ndmin=1)
    _write_uint64(stream, array)

cpdef _write_uint64(BitStream stream, np.ndarray[np.uint64_t, ndim=1] uint64s):
    """
    Write a 1-dim. arrray of unsigned 64-bit integers into a stream.
    """
    cdef unsigned char* _bytes
    cdef size_t i, num_uint64s, byte_index
    cdef unsigned long bit_length, bit_index, bit_index_c
    cdef unsigned char mask1, mask2, base, byte
                            
    num_uint64s = len(uint64s)
    stream._extend(64 * num_uint64s)
    _bytes = stream._bytes

    byte_index = stream._write_offset / 8
    bit_index  = stream._write_offset - 8 * byte_index
    bit_index_c = 8 - bit_index

    mask2 = 255 >> bit_index
    mask1 = 255 - mask2
    
    if bit_index == 0:
        for i in range(num_uint64s):
            _bytes[byte_index + 8*i  ] = <unsigned char>((uint64s[i] >> 56) & 255)
            _bytes[byte_index + 8*i+1] = <unsigned char>((uint64s[i] >> 48) & 255)
            _bytes[byte_index + 8*i+2] = <unsigned char>((uint64s[i] >> 40) & 255)
            _bytes[byte_index + 8*i+3] = <unsigned char>((uint64s[i] >> 32) & 255)
            _bytes[byte_index + 8*i+4] = <unsigned char>((uint64s[i] >> 24) & 255)
            _bytes[byte_index + 8*i+5] = <unsigned char>((uint64s[i] >> 16) & 255)
            _bytes[byte_index + 8*i+6] = <unsigned char>((uint64s[i] >>  8) & 255)
            _bytes[byte_index + 8*i+7] = <unsigned char>((uint64s[i]      ) & 255)
    else:
        for i in range(num_uint64s):
            for s in range(8):
                base = (uint64s[i] >> (8 * (7 - s))) & 255                   
                byte = (<unsigned char>base) >> bit_index
                _bytes[byte_index + 8*i+s] = \
                  (_bytes[byte_index + 8*i+s] & mask1) | byte
                byte = ((<unsigned char>base) << bit_index) & 255
                _bytes[byte_index + 8*i+s+1] = \
                  (_bytes[byte_index + 8*i+s+1] & mask2) | byte
    stream._write_offset += 64 * num_uint64s

register(uint64, reader=read_uint64, writer=write_uint64)

cpdef read_int64(BitStream stream, n=None):
    """
    Read signed 64-bit integers from a stream.
    """
    return read_uint64(stream, n).astype("int64")

cpdef write_int64(BitStream stream, data):
    """
    Write signed 64-bit integers into a stream.
    """
    array = numpy.array(data, int64, copy=false, ndmin=1)
    _write_int64(stream, array)

cpdef _write_int64(BitStream stream, np.ndarray[np.int64_t, ndim=1] int64s):
    """
    Write a 1-dim. arrray of unsigned 64-bit integers into a stream.
    """
    cdef unsigned char* _bytes
    cdef size_t i, num_int64s, byte_index
    cdef unsigned long bit_length, bit_index, bit_index_c
    cdef unsigned char mask1, mask2, base, byte
                            
    num_int64s = len(int64s)
    stream._extend(64 * num_int64s)
    _bytes = stream._bytes

    byte_index = stream._write_offset / 8
    bit_index  = stream._write_offset - 8 * byte_index
    bit_index_c = 8 - bit_index

    mask2 = 255 >> bit_index
    mask1 = 255 - mask2
    
    if bit_index == 0:
        for i in range(num_int64s):
            _bytes[byte_index + 8*i  ] = <unsigned char>((int64s[i] >> 56) & 255)
            _bytes[byte_index + 8*i+1] = <unsigned char>((int64s[i] >> 48) & 255)
            _bytes[byte_index + 8*i+2] = <unsigned char>((int64s[i] >> 40) & 255)
            _bytes[byte_index + 8*i+3] = <unsigned char>((int64s[i] >> 32) & 255)
            _bytes[byte_index + 8*i+4] = <unsigned char>((int64s[i] >> 24) & 255)
            _bytes[byte_index + 8*i+5] = <unsigned char>((int64s[i] >> 16) & 255)
            _bytes[byte_index + 8*i+6] = <unsigned char>((int64s[i] >>  8) & 255)
            _bytes[byte_index + 8*i+7] = <unsigned char>((int64s[i]      ) & 255)
    else:
        for i in range(num_int64s):
            for s in range(8):
                base = (int64s[i] >> (8 * (7 - s))) & 255                   
                byte = (<unsigned char>base) >> bit_index
                _bytes[byte_index + 8*i+s] = \
                  (_bytes[byte_index + 8*i+s] & mask1) | byte
                byte = ((<unsigned char>base) << bit_index) & 255
                _bytes[byte_index + 8*i+s+1] = \
                  (_bytes[byte_index + 8*i+s+1] & mask2) | byte
    stream._write_offset += 64 * num_int64s

register(int64, reader=read_int64, writer=write_int64)

#
# Floating-Point Data Reader and Writer: 64 bits (double)
# ------------------------------------------------------------------------------
#

cpdef read_float64(BitStream stream, n=None):
    """
    Read 64-bit floating-point numbers (doubles) from a stream.
    """
    cdef size_t n_

    if n is None:
        n_ = 1
    else:
        n_ = n

    chars = read_str(stream, 8*n_)
    float64s = struct.unpack(">" + n_*"d", chars) # big-endian

    if n is None:
        return float64s[0]
    else:
        return numpy.array(float64s, dtype=numpy.float64)

cpdef write_float64(BitStream stream, data):
    """
    Write 64-bit floating-point numbers (doubles) into a stream.
    """
    array = numpy.array(data, dtype=float64, copy=False, ndmin=1)
    _write_float64(stream, array)

cpdef _write_float64(BitStream stream, np.ndarray[np.float64_t, ndim=1] float64s):
    """
    Write a 1-dim. array of 64-bit floating-point numbers into a stream.
    """
    # Comment: The function `_PyFloat_Pack8` belongs to the Python API. 
    #           Refer to "floatobject.h" (included by "Python.h") for details.
    #
    # TODO: management on errors of `_PyFloat_Pack8`

    cdef size_t num_floats

    cdef size_t byte_offset
    cdef unsigned char bit_offset, bit_offset_c
    cdef unsigned char* pointer

    cdef size_t i
    cdef unsigned char j
    cdef unsigned char *_buffer = [0, 0, 0, 0, 0, 0, 0, 0]
    cdef double _float


    num_floats = len(float64s)
    stream._extend(64 * num_floats)

    bit_offset  = stream._write_offset % 8
    byte_offset = stream._write_offset / 8
    pointer = stream._bytes + byte_offset
    if bit_offset == 0:
        for _float in float64s:
            _PyFloat_Pack8(_float, pointer, 0) # 0 is for big endian.
            pointer += 8
    else:
        bit_offset_c = 8 - bit_offset
        for _float in float64s:
            _PyFloat_Pack8(_float, _buffer, 0)
            for i in range(8):
                # rk: we're doing *a lot* of useless pointer reads (overridden)
                #     for the sake of not having to write specialize code for 
                #     the first and last byte of the target.
                pointer[i  ] =  (pointer[i  ] & (255 << bit_offset_c)) + \
                               ((_buffer[i  ] & (255 << bit_offset  )) >> bit_offset  )
                pointer[i+1] = ((_buffer[i  ] & (255 >> bit_offset_c)) << bit_offset_c) + \
                                (pointer[i+1] & (255 >> bit_offset))
            pointer = pointer + 8
    stream._write_offset += 64 * num_floats

register(numpy.float64, reader=read_float64, writer=write_float64)
register(float, reader=read_float64, writer=write_float64)

#
# String Reader / Writer
# ------------------------------------------------------------------------------
#

cpdef read_str(BitStream stream, n=None):
    """
    Read a string from a stream.
    """
    if n is None: # have a more consistent API and consider that None is 1 char ?
        if (len(stream) % 8) != 0: # Really ? Accept and let the user check ?
            raise ReadError("cannot empty the stream.")
        else:
            n = len(stream) / 8
    elif n > len(stream) / 8:
        raise ReadError("end of stream")
    return read_uint8(stream, n).tostring()

cpdef write_str(BitStream stream, string):
    """
    Write a string into a stream.
    """
    array = numpy.fromstring(string, dtype=uint8)
    _write_uint8(stream, array)

register(str, reader=read_str, writer=write_str)

#
# BitStream Reader/Writer
# ------------------------------------------------------------------------------
#
cpdef write_bitstream(BitStream sink, BitStream source):
    """
    Write the stream `source` into the stream `sink`.
    """
    write_uint8(sink, read_uint8(source, len(source) / 8))
    write_bool(sink, read_bool(source, len(source)))

cpdef read_bitstream(BitStream source, n=None):
    """
    Read a stream from a stream.
    """
    cdef BitStream sink
    cdef size_t start_byte_index_start, end_byte_index, num_bits, new_num_bytes
    if n is None:
        num_bits = len(source) # read the whole stream
    elif n > len(source):
        raise ReadError("end of stream")
    else:
        num_bits = n 

    if num_bits == 0:
        return BitStream()
    else:
        start_byte_index = source._read_offset / 8 # byte index of the first bit
        # byte index of the last bit needed.
        end_byte_index   = (source._read_offset + num_bits - 1) / 8
        new_num_bytes = end_byte_index - start_byte_index + 1

    sink = BitStream()
    sink._extend(8 * new_num_bytes)
    memcpy(sink._bytes, &source._bytes[start_byte_index], new_num_bytes)

    sink._read_offset  = source._read_offset  - 8 * start_byte_index
    sink._write_offset = sink._read_offset + num_bits
    source._read_offset += num_bits
    return sink

register(BitStream, reader=read_bitstream, writer=write_bitstream)

#
# Hex Dump
# ------------------------------------------------------------------------------
#

# TODO: see man hexdump and look for "canonical display"
def format_hex(integer, length):
    hex_ = hex(integer)[2:]
    pad = (length - len(hex_)) * "0"
    return pad + hex_

def hex_dump(stream):
    stream = stream.copy()
    offset = 0
    try: 
        while len(stream) > 0:
            print format_hex(offset, 7),
            for i in range(6):
                print format_hex(stream.read_uint16(stream), 4),
            print
            offset += 12
    except ReadError:
        pass # forget about trailing bits

