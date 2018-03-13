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

