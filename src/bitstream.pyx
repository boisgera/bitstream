# cython: profile = True
# coding: utf-8

"""
Binary Data for Humans: <http://boisgera.github.io/bitstream/>
"""


# Imports
# ------------------------------------------------------------------------------

# Standard Python Library
try: 
    import builtins
except:
    import __builtin__ as builtins
cdef object builtins_type = builtins.type
import atexit
import copy
import doctest
import hashlib
import os.path
import shutil
import struct
import sys
import tempfile
import timeit

# Third Party Libraries
import numpy
import setuptools
import pkg_resources

# Cython
cimport cython
cimport numpy as np
from libc.stdlib cimport malloc, realloc, free
from libc.string cimport memcpy
from cpython cimport bool as boolean, Py_INCREF, Py_DECREF, PyObject, PyObject_GetIter, PyErr_Clear
cdef extern from "Python.h":
    int _PyFloat_Pack8 (double, unsigned char *, int) except -1


# Metadata
# ------------------------------------------------------------------------------
__author__ = u"Sébastien Boisgérault <Sebastien.Boisgerault@mines-paristech.fr>"
__license__ = "MIT License"


# Constants
# ------------------------------------------------------------------------------
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


# Cython Interface (pxd file)
# ------------------------------------------------------------------------------
_include = None

_pxd_src = b"""\
cimport numpy as np

cdef class BitStream:
    cdef unsigned char *_bytes
    cdef size_t _num_bytes
    cdef unsigned long long _read_offset
    cdef unsigned long long _write_offset
    cdef public list _states
    cdef unsigned int _state_id

    cdef dict readers    
    cdef dict writers

    cpdef int _extend(BitStream self, size_t num_bits) except -1
    cpdef write(BitStream self, data, object type=?)
    cpdef read(BitStream self, object type=?, n=?)
    cpdef copy(BitStream self, n=?)
    cpdef State save(BitStream self)
    cpdef restore(BitStream self, State state)

cdef class State:
    cdef readonly BitStream _stream
    cdef readonly unsigned long long _read_offset
    cdef readonly unsigned long long _write_offset
    cdef readonly unsigned int _id

cpdef read_bool(BitStream stream, n=?)
cpdef write_bool(BitStream stream, bools)
cpdef write_uint8(BitStream stream, data)
cpdef _write_uint8(BitStream stream, np.ndarray[np.uint8_t, ndim=1] uint8s)
cpdef read_uint8(BitStream stream, n=?)
cpdef write_int8(BitStream stream, data)
cpdef _write_int8(BitStream stream, np.ndarray[np.int8_t, ndim=1] int8s)
cpdef read_int8(BitStream stream, n=?)
cpdef read_uint16(BitStream stream, n=?)
cpdef write_uint16(BitStream stream, data)
cpdef _write_uint16(BitStream stream, np.ndarray[np.uint16_t, ndim=1] uint16s)
cpdef read_int16(BitStream stream, n=?)
cpdef write_int16(BitStream stream, data)
cpdef _write_int16(BitStream stream, np.ndarray[np.int16_t, ndim=1] int16s)
cpdef read_uint32(BitStream stream, n=?)
cpdef write_uint32(BitStream stream, data)
cpdef _write_uint32(BitStream stream, np.ndarray[np.uint32_t, ndim=1] uint32s)
cpdef read_int32(BitStream stream, n=?)
cpdef write_int32(BitStream stream, data)
cpdef _write_int32(BitStream stream, np.ndarray[np.int32_t, ndim=1] int32s)
cpdef read_uint64(BitStream stream, n=?)
cpdef write_uint64(BitStream stream, data)
cpdef _write_uint64(BitStream stream, np.ndarray[np.uint64_t, ndim=1] uint64s)
cpdef read_int64(BitStream stream, n=?)
cpdef write_int64(BitStream stream, data)
cpdef _write_int64(BitStream stream, np.ndarray[np.int64_t, ndim=1] int64s)
cpdef read_float64(BitStream stream, n=?)
cpdef write_float64(BitStream stream, data)
cpdef _write_float64(BitStream stream, np.ndarray[np.float64_t, ndim=1] float64s)
cpdef read_bytes(BitStream stream, n=?)
cpdef write_bytes(BitStream stream, string)
cpdef write_bitstream(BitStream sink, BitStream source)
cpdef read_bitstream(BitStream source, n=?)
"""

def get_include():
    "Return a path to a directory that contains the bitstream pxd file"
    global _include
    if _include is None:
        _include = tempfile.mkdtemp(prefix='bitstream-')
        pxd_path = os.path.join(_include, 'bitstream.pxd')
        pxd_file = open(pxd_path, 'wb')
        pxd_file.write(_pxd_src)
        pxd_file.close()
    return _include

def _cleanup():
    if _include is not None:
        shutil.rmtree(_include)

# Do NOT remove automatically the _include directory; 
# we may leak a few files but we will avoid some bugs.
#
# atexit.register(_cleanup)


# Helpers (not used)
# ------------------------------------------------------------------------------
cdef inline size_t div8(unsigned long long value):
    return value >> 3

cdef inline unsigned char rem8(unsigned long long value):
    return value & 7


# BitStream
# ------------------------------------------------------------------------------
cdef class BitStream:
    """
    BitStream class / constructor

    Arguments
    ---------------------------------------------------------------------------- 
   
      - without arguments, `BitStream()` creates an empty bitstream.

      - with arguments, `BitStream(*args, **kwargs)`
        also forwards the arguments to the `write` method.

    Usage
    ----------------------------------------------------------------------------

        >>> stream = BitStream()
        >>> stream = BitStream([False, True])
        >>> stream = BitStream("Hello", bytes)
        >>> stream = BitStream(42, uint8)
    """    
    def __cinit__(self):
        self._read_offset = 0
        self._write_offset = 0
        self._num_bytes = 0
        self._bytes = NULL

        cdef State state = State.__new__(State)
        state._stream = self
        state._read_offset = self._read_offset
        state._write_offset = self._write_offset
        state._id = self._state_id
        self._states = [state]
        self._state_id = 0

    def __init__(self, *args, **kwargs):
        if args or kwargs:
            self.write(*args, **kwargs)

    cpdef int _extend(BitStream self, size_t num_bits) except -1:
        """
        Make room for `num_bits` extra bits into the stream.

        Warning: a reallocation may take place and invalidate `self._bytes`.
        The attributes `_read_offset` and `_write_offset` are unchanged.
        """
        cdef long num_extra_bits
        cdef size_t num_extra_bytes, new_num_bytes        
        
        num_extra_bits = num_bits + self._write_offset - 8 * self._num_bytes
        if num_extra_bits > 0:
            num_extra_bytes = num_extra_bits // 8
            num_extra_bits  = num_extra_bits - 8 * num_extra_bytes
            new_num_bytes = self._num_bytes + num_extra_bytes + (num_extra_bits != 0)
            self._bytes = <unsigned char *>realloc(self._bytes, new_num_bytes)
            self._num_bytes = new_num_bytes
        return 0

    cpdef write(BitStream self, data, type=None):
        """
        Encode `data` and append it to the stream.

        Arguments
        ------------------------------------------------------------------------

          - `data` is the data to be encoded.

            Its type should be consistent with the `type` argument.

          - `type` is a type identifier (such as `bool`, `bytes`, `int8`, etc.).

            It is optional if `data` is an instance
            of a registered type or a
            list or 1d NumPy array of such 
            instances.

        Usage
        ------------------------------------------------------------------------

            >>> stream = BitStream()
            >>> stream.write(True, bool)       # explicit bool type
            >>> stream.write(False)            # implicit bool type
            >>> stream.write(3*[False], bool)  # list (explicit type)
            >>> stream.write(3*[True])         # list (implicit type)
            >>> stream.write("AB", bytes)      # bytes
            >>> stream.write(-128, int8)       # signed 8 bit integer
        """
        cdef size_t length
        cdef int auto_detect = 0
        type_error = "unsupported type {0!r}."

        # no data
        if data is None:
            return

        # automatic type detection
        if type is None:
            auto_detect = 1
            # single bool optimization
            if data is true or data is false:
                type = bool
            else:
                data_type = builtins_type(data)
                if data_type is list:
                    if len(data) == 0:
                        return
                    else:
                        type = builtins_type(data[0])                  
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
        elif type is bytes:
            write_bytes(self, data)
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
        elif auto_detect or isinstance(type, builtins_type):
            writer = _writers.get(type)
            if writer is None:
                raise TypeError(type_error.format(type.__name__))
            writer(self, data)
        # lookup for a writer *factory*
        else: 
            instance = type
            type = builtins_type(instance)
            writer_factory = _writers.get(type)
            if writer_factory is None:
                raise TypeError(type_error.format(type.__name__))
            else:
                writer = writer_factory(instance)
            writer(self, data)

    cpdef read(BitStream self, type=None, n=None): 
        """
        Decode and consume `n` items of `data` from the start of the stream.

        Arguments
        ------------------------------------------------------------------------

          - `type`: type identifier (such as `bool`, `bytes`, `int8`, etc.)
         
            If `type` is `None` a bitstream is returned.

          - `n`: number of items to read

            For most types, `n=None` reads one item, 
            but some types use a different convention.

        Returns
        ------------------------------------------------------------------------

          - `data`: `n` items of data

            The type of data depends on `type` and `n`.

        Usage
        ------------------------------------------------------------------------

            >>> stream = BitStream("Hello World!")
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
        """
        if isinstance(type, int) and n is None:
            n = type
            type = None
        if type is None:
            type = BitStream

        # find the appropriate reader
        if type is bool:
            return read_bool(self, n)
        elif type is uint8:
            return read_uint8(self, n)
        elif type is int8:
            return read_int8(self, n)
        elif type is bytes:
            return read_bytes(self, n)
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
        elif isinstance(type, builtins_type):
            reader = _readers.get(type)
            if reader:
                return reader(self, n)
            else:
                raise TypeError("unsupported type {0!r}.".format(type.__name__))
        else: # lookup for a reader *factory*
            instance = type
            type = builtins_type(instance)
            reader_factory = _readers.get(type)
            if reader_factory is None:
                raise TypeError("unsupported type {0!r}.".format(type.__name__))
            else:
                reader = reader_factory(instance)
                return reader(self, n)

    # TODO: implement __unicode__ and change __str__ accordingly

    def __str__(self):
        """
        Represent the stream as a string of `'0'` and `'1'`.

        Usage
        ------------------------------------------------------------------------

            >>> print BitStream("ABC")
            010000010100001001000011
        """
        bools = []
        len_ = self._write_offset - self._read_offset
        for i in range(len_):
            byte_index, bit_index = divmod(self._read_offset + i, 8)
            mask = 128 >> bit_index
            bools.append(bool(self._bytes[byte_index] & mask))
        return "".join([str(int(bool_)) for bool_ in bools])

    def __repr__(self):
        """
        Represent the stream as a string of `'0'` and `'1'`.

        Usage
        ------------------------------------------------------------------------

            >>> BitStream("ABC")
            010000010100001001000011
        """
        return str(self)

    # Copy Methods
    # --------------------------------------------------------------------------
    cpdef copy(BitStream self, n=None):
        """
        Copy (partially or totally) the stream.

        Copies do not consume the stream they read.

        Arguments
        ------------------------------------------------------------------------

          - `n`: unsigned integer of `None`.

            The number of bits to copy from the start of the stream. 
            The full stream is copied if `n` is None.

        Returns
        ------------------------------------------------------------------------

          - `stream`: a bitstream.

        Raises
        ------------------------------------------------------------------------

          - `ReadError` if `n` is larger than the length of the stream.

        Usage
        ------------------------------------------------------------------------

            >>> stream = BitStream("A")
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
        """
        cdef unsigned long long read_offset = self._read_offset
        copy = read_bitstream(self, n)
        self._read_offset = read_offset
        return copy

    def __copy__(self):
        """
        Bitstream shallow copy.

        Usage
        ------------------------------------------------------------------------

            >>> from copy import copy
            >>> stream = BitStream("A")
            >>> stream
            01000001
            >>> copy(stream)
            01000001
            >>> stream
            01000001
        """
        return self.copy()
    
    def __deepcopy__(self, memo):
        """
        Bitstream deep copy.

        Usage
        ------------------------------------------------------------------------

            >>> from copy import deepcopy
            >>> stream = BitStream("A")
            >>> stream
            01000001
            >>> deepcopy(stream)
            01000001
            >>> stream
            01000001
        """
        return self.copy()
        

    # Length and Comparison
    # --------------------------------------------------------------------------
    def __len__(self):
        """
        Return the bitstream length in bits.

        Usage
        ------------------------------------------------------------------------

            >>> stream = BitStream([True, False])
            >>> len(stream) 
            2

            >>> stream = BitStream("ABC")
            >>> len(stream)
            24
            >>> len(stream) /// 8
            3
            >>> len(stream) % 8
            0
        """
        return self._write_offset - self._read_offset

    def __richcmp__(BitStream self, other, int operation):
        """
        Equality / Inequality operators

        Usage
        ------------------------------------------------------------------------

            >>> BitStream(True) == BitStream(True)
            True
            >>> BitStream(True) == BitStream([True])
            True
            >>> BitStream(True) == BitStream(False)
            False
            >>> BitStream(True) == BitStream([True, False])
            False
            >>> BitStream(True) != BitStream(True)
            False
            >>> BitStream(True) != BitStream([True])
            False
            >>> BitStream(True) != BitStream(False)
            True
            >>> BitStream(True) != BitStream([True, False])
            True

            >>> ord("A")
            65
            >>> BitStream("A") == BitStream(65, uint8)
            True
            >>> BitStream("A") == BitStream(66, uint8)
            False
            >>> BitStream("A") != BitStream(65, uint8)
            False
            >>> BitStream("A") != BitStream(66, uint8)
            True
        """
        # see http://docs.cython.org/src/userguide/special_methods.html
        cdef boolean equal
        if operation not in (2, 3):
            raise NotImplementedError()
        if not isinstance(other, BitStream):
            equal = false
        else:
           s1 = self.copy()
           s2 = other.copy() # test for type, 
           equal = all(s1.read(numpy.uint8, len(s1) // 8) == s2.read(numpy.uint8, len(s2) // 8)) and\
                   (s1.read(bool, len(s1)) == s2.read(bool, len(s2)))
        if operation == 2:
            return equal
        else:
            return not equal

    def __hash__(self):
        """
        Compute a bitstream hash 

        The computed hash is consistent with the equality operator.
        """
        copy = self.copy()
        uint8s = copy.read(numpy.uint8, len(self) // 8)
        bools  = copy.read(bool, len(copy))
        return hash((hashlib.sha1(uint8s).hexdigest(), tuple(bools)))


    # Snapshots
    # --------------------------------------------------------------------------
    cpdef State save(BitStream self):
        """
        Return a `State` instance
        """
        cdef State state
        state = self._states[-1]
        if state._read_offset != self._read_offset or \
           state._write_offset != self._write_offset:
            self._state_id = self._state_id + 1
            # Fast instantiation (<http://docs.cython.org/src/userguide/extension_types.html>)
            state = State.__new__(State)
            # For some reason, setting the state data in constructors would
            # trigger the (slow) conversion of these data to Python objects.
            # That may have been corrected in late 0.19.x versions of Cython.
            state._stream = self
            state._read_offset = self._read_offset
            state._write_offset = self._write_offset
            state._id = self._state_id
            self._states.append(state)
        return state

    cpdef restore(BitStream self, State state):
        """
        Restore a previous stream state.

        Raise a `ValueError` if the state is invalid.
        """
        if self is not state._stream:
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


# Types Registration
# ------------------------------------------------------------------------------
cdef dict _readers = {}
cdef dict _writers = {}

def register(type, reader=None, writer=None):
    if reader is not None:
        _readers[type] = reader
    if writer is not None:
        _writers[type] = writer


# Exceptions
# ------------------------------------------------------------------------------
class ReadError(Exception):
    """
    Exception raised when a binary decoding is impossible.
    """

class WriteError(Exception):
    """
    Exception raised when a binary encoding is impossible.
    """


# Bitstream State
# ------------------------------------------------------------------------------
cdef class State: # treat as opaque and immutable.
    """
    The (opaque) type of stream state.
    """
    def __richcmp__(self, State other, int operation):
        # see http://docs.cython.org/src/userguide/special_methods.html
        cdef boolean equal
        if operation not in (2, 3):
            raise NotImplementedError()
        equal = self._stream is other._stream and \
                self._read_offset == other._read_offset and \
                self._write_offset == other._write_offset and \
                self._id == other._id
        if operation == 2:
            return equal
        else:
            return not equal


# Bool Reader / Writer
# ------------------------------------------------------------------------------
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
        byte_index = stream._read_offset // 8
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
        byte_index = (stream._read_offset + i ) // 8
        bit_index  = (stream._read_offset + i ) - 8 * byte_index            
        mask = 128 >> bit_index
        bools[i] = bool(_bytes[byte_index] & mask)
    stream._read_offset += _n
    return bools

cpdef write_bool(BitStream stream, bools):
    """
    Write bools into a stream.
    """
    cdef unsigned char *_bytes
    cdef unsigned char _byte
    cdef unsigned char mask
    cdef unsigned long long i, n
    cdef size_t byte_index
    cdef unsigned char bit_index
    cdef long long offset
    cdef list _bools
    cdef type _type
    cdef np.uint8_t _np_bool

    offset = stream._write_offset
    if bools is false or bools is zero: # False or 0 (if cached).
        stream._extend(1)
        _bytes = stream._bytes
        byte_index = offset >> 3
        bit_index  = offset & 7
        mask = 128 >> bit_index
        _bytes[byte_index] = _bytes[byte_index] & ~mask
        stream._write_offset += 1
    elif bools is true or bools is one: # True or 1 (if cached).
        stream._extend(1)
        _bytes = stream._bytes
        byte_index = offset >> 3
        bit_index  = offset & 7
        mask = 128 >> bit_index
        _bytes[byte_index] = _bytes[byte_index] | mask
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
                byte_index = (offset + i) >> 3
                bit_index  = (offset + i) & 7
                _byte = _bytes[byte_index]
                mask = 128 >> bit_index
                if _bool is false:
                    _bytes[byte_index] = _byte & ~mask
                elif _bool is true or _bool:
                    _bytes[byte_index] = _byte | mask
                else:
                    _bytes[byte_index] = _byte & ~mask
                i += 1
            stream._write_offset += n
        elif _type is ndarray:
            n = len(bools)
            stream._extend(n)
            _bytes = stream._bytes
            i = 0
            for _bool in bools:
                byte_index = (offset + i) >> 3
                bit_index  = (offset + i) & 7
                mask = 128 >> bit_index
                _byte = _bytes[byte_index]
                if _bool:
                    _bytes[byte_index] = _byte | mask
                else:
                    _bytes[byte_index] = _byte & ~mask
                i += 1
            stream._write_offset += n
        elif bools:
            stream._extend(1)
            _bytes = stream._bytes
            byte_index = offset >> 3
            bit_index  = offset & 7
            mask = 128 >> bit_index
            _bytes[byte_index] = _bytes[byte_index] | mask
            stream._write_offset += 1
        else:
            stream._extend(1)
            _bytes = stream._bytes
            byte_index = offset >> 3
            bit_index  = offset & 7
            mask = 128 >> bit_index
            _bytes[byte_index] = _bytes[byte_index] & ~mask
            stream._write_offset += 1

register(bool, reader=read_bool, writer=write_bool)
register(numpy.bool_, reader=read_bool, writer=write_bool)


# Integers Type Readers and Writers: signed/unsigned, 8/16/32 bits integers
# ------------------------------------------------------------------------------
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

    byte_index = stream._write_offset // 8
    bit_index  = stream._write_offset - 8 * byte_index
    bit_index_c = 8 - bit_index
    mask2 = 255 >> bit_index
    mask1 = 255 - mask2
    
    _type = type(data)
    
    if _type is list or _type is np.ndarray: 
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
    
    byte_index = stream._write_offset // 8
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
    byte_index = stream._read_offset // 8
    bit_index  = stream._read_offset - 8 * byte_index
    bit_index_c = 8 - bit_index
    
    if n is None:
        if len(stream) < 8:
            raise ReadError("end of stream")
        stream._read_offset += 8
        if bit_index == 0:
            return uint8(_bytes[byte_index])
        else:
          bit_index_c = 8 - bit_index
          mask1 = 255 >> bit_index
          mask2 = 255 - mask1
          _byte = ((_bytes[byte_index    ] & mask1) << bit_index) + \
                  ((_bytes[byte_index + 1] & mask2) >> bit_index_c)         
          return uint8(_byte)
    
    if len(stream) < 8 * n:
        raise ReadError("end of stream")
    num_bytes = min(n, len(stream) // 8)
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

    byte_index = stream._write_offset // 8
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
    byte_index = stream._read_offset // 8
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
    _bytes = stream._bytes

    byte_index = stream._write_offset // 8
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

    byte_index = stream._write_offset // 8
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
    byte_index = stream._read_offset // 8
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

    byte_index = stream._write_offset // 8
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

    byte_index = stream._write_offset // 8
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
    byte_index = stream._read_offset // 8
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

    byte_index = stream._write_offset // 8
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

    byte_index = stream._write_offset // 8
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

# Floating-Point Data Reader and Writer: 64 bits (double)
# ------------------------------------------------------------------------------
cpdef read_float64(BitStream stream, n=None):
    """
    Read 64-bit floating-point numbers (doubles) from a stream.
    """
    cdef size_t n_

    if n is None:
        n_ = 1
    else:
        n_ = n

    chars = read_bytes(stream, 8*n_)
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
    byte_offset = stream._write_offset // 8
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
                pointer[i  ] =  (pointer[i  ] & (255 << bit_offset_c)) + \
                               ((_buffer[i  ] & (255 << bit_offset  )) >> bit_offset  )
                pointer[i+1] = ((_buffer[i  ] & (255 >> bit_offset_c)) << bit_offset_c) + \
                                (pointer[i+1] & (255 >> bit_offset))
            pointer = pointer + 8
    stream._write_offset += 64 * num_floats

register(numpy.float64, reader=read_float64, writer=write_float64)
register(float, reader=read_float64, writer=write_float64)


# String Reader / Writer
# ------------------------------------------------------------------------------
cpdef read_bytes(BitStream stream, n=None):
    """
    Read a string from a stream.
    """
    if n is None:
        if (len(stream) % 8) != 0:
            raise ReadError("cannot empty the stream.")
        else:
            n = len(stream) // 8
    elif n > len(stream) // 8:
        raise ReadError("end of stream")
    return read_uint8(stream, n).tobytes()

cpdef write_bytes(BitStream stream, string):
    """
    Write a string into a stream.
    """
    array = numpy.frombuffer(string, dtype=uint8)
    _write_uint8(stream, array)

register(bytes, reader=read_bytes, writer=write_bytes)


# BitStream Reader/Writer
# ------------------------------------------------------------------------------
cpdef write_bitstream(BitStream sink, BitStream source):
    """
    Write the stream `source` into the stream `sink`.
    """
    write_uint8(sink, read_uint8(source, len(source) // 8))
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
        start_byte_index = source._read_offset // 8 # byte index of the first bit
        # byte index of the last bit needed.
        end_byte_index   = (source._read_offset + num_bits - 1) // 8
        new_num_bytes = end_byte_index - start_byte_index + 1

    sink = BitStream()
    sink._extend(8 * new_num_bytes)
    memcpy(sink._bytes, &source._bytes[start_byte_index], new_num_bytes)

    sink._read_offset  = source._read_offset  - 8 * start_byte_index
    sink._write_offset = sink._read_offset + num_bits
    source._read_offset += num_bits
    return sink

register(BitStream, reader=read_bitstream, writer=write_bitstream)

