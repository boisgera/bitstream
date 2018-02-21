
Snapshots
================================================================================

A stream is a simple model to deal with binary data,
but sometimes you need more: you want to perform some lookahead without 
changing the stream or you want to try some read/write operations 
but go back to the initial state if they fail. 
At this stage, you probably have copies of streams 
everywhere and the stream interface seems very cumbersome.

Therefore, we provide snapshots, a simple solution for these
use cases that doesn't require copies of streams:
you can save the state of a stream at any 
stage in a sequence of read/write operations and restore 
any such state later if you need it.


Lookahead
--------------------------------------------------------------------------------

The type of binary data can usually be identified by a specific header
coded in its first few bytes.
For example, [WAVE] audio can be detected with the function:

[WAVE]: https://en.wikipedia.org/wiki/WAV

    >>> from bitstream import BitStream, ReadError

    >>> def is_wave(stream):
    ...    try:
    ...        riff = stream.read(bytes, 4)
    ...        _ = stream.read(bytes, 4)
    ...        wave = stream.read(bytes, 4)
    ...        return (riff == "RIFF") and (wave == "WAVE")
    ...    except ReadError:
    ...        return False
    
The contents of an empty single-channel 44.1 kHz WAVE audio file are for example

    >>> wave = 'RIFF$\x00\x00\x00WAVEfmt \x10\x00\x00\x00\x01\x00\x01\x00D\xac\x00\x00\x88X\x01\x00\x02\x00\x10\x00data\x00\x00\x00\x00'

The function `is_wave` above works as expected at first

    >>> stream = BitStream(wave)
    >>> is_wave(stream)
    True

but another attempt gives an incorrect answer:

    >>> is_wave(stream)
    False

The explanation is simple: to identify the header of a WAVE file,
we need to consume the first 12 bytes in the stream. 
Since this header is missing from the stream afterwards, 
the new attempt fails.

To solve this issue, 
it's possible to make `is_wave` perform a (partial) copy of the stream 
and perform the check on the copy, leaving the initial 
stream unchanged. 
However in general this approach may be cumbersome;
copies should also be avoided when possible for performance reasons.

Bitstream also supports snapshots, 
a better way to deal with lookaheads.
With them you can:

  - save the state of a stream at any time, 

  - perform arbitrary operations on it and then 

  - restore its initial state.

The implementation of `is_wave` that does this is plain;
we just make sure that whatever happens 
(even an error in the processing) 
the original state of the stream is restored at the end. 

    >>> def is_wave(stream):
    ...     snapshot = stream.save()
    ...     try:
    ...         riff = stream.read(bytes, 4)
    ...         _ = stream.read(bytes, 4)
    ...         wave = stream.read(bytes, 4)
    ...         return (riff == "RIFF") and (wave == "WAVE")
    ...     except ReadError:
    ...         return False
    ...     finally:
    ...         stream.restore(snapshot)

This version works as expected:

    >>> wave = 'RIFF$\x00\x00\x00WAVEfmt \x10\x00\x00\x00\x01\x00\x01\x00D\xac\x00\x00\x88X\x01\x00\x02\x00\x10\x00data\x00\x00\x00\x00'
    >>> stream = BitStream(wave)
    >>> copy = stream.copy()
    >>> is_wave(stream)
    True
    >>> stream == copy
    True
    >>> is_wave(stream)
    True



Exception Safety
--------------------------------------------------------------------------------

Consider the toy DNA reader below:

    >>> def DNA_read(stream, n=1):
    ...     DNA_bases = "ACGT"
    ...     bases = []
    ...     for i in range(n):
    ...         base = stream.read(bytes, 1)
    ...         if base not in DNA_bases:
    ...             error = "invalid base {0!r}".format(base)
    ...             raise ReadError(error)
    ...         else:
    ...             bases.append(base)
    ...     return "".join(bases)


It reads DNA sequences represented as strings of 
`'A'`, `'C'`, `'G'` and `'T'` characters:

    >>> dna = BitStream(b"GATA")
    >>> DNA_read(dna, 4)
    'GATA'

If there is a `'U'` in the sequence, this is an error since
the [uracil base](https://en.wikipedia.org/wiki/Nucleobase) 
is only found in RNA.

    >>> stream = BitStream(b"GAUTA") # invalid DNA sequence

The DNA reader correctly rejects the code

    >>> DNA_read(stream, 4)
    Traceback (most recent call last):
    ...
    ReadError: invalid base 'U'

but the initial stream is partially consumed in the process:

    >>> stream.read(bytes)
    'TA'

This implementation therefore only provides some basic exception safety.
A reader that preserves the original value of the stream when an error
occurs would provide [strong exception safety](https://en.wikipedia.org/wiki/Exception_safety) instead.
With snapshots, the modifications required to support this 
are plain: we simply restore the original stream whenever an
error occurs

    >>> def DNA_read(stream, n=1):
    ...     DNA_bases = b"ACGT"
    ...     snapshot = stream.save()
    ...     try:
    ...         bases = []
    ...         for i in range(n):
    ...             base = stream.read(bytes, 1)
    ...             if base not in DNA_bases:
    ...                 error = "invalid base {0!r}".format(base)
    ...                 raise ReadError(error)
    ...             else:
    ...                 bases.append(base)
    ...         return "".join(bases)
    ...     except:
    ...         stream.restore(snapshot)
    ...         raise

With this new version, reading an invalid DNA code still 
raises an exception

    >>> stream = BitStream(b"GAUTA") # invalid DNA sequence
    >>> DNA_read(stream, 4)
    Traceback (most recent call last):
    ...
    ReadError: invalid base 'U'

but now the original stream is intact

    >>> stream.read(bytes)
    'GAUTA'


Multiple Snapshots
--------------------------------------------------------------------------------

You can create snapshots of a stream at any stage between read/write operations.
Multiple snapshots enable for example the implemention a hierarchy of readers 
or writers that provide strong exception safety at every level.

However arbitrary sequences of save and restore are not allowed:
when a given snapshot is restored, the snapshots that were created 
between the snapshot creation and before its restoration are forgotten.
In other words, saves and restores can only be applied in reverse order.
Of course it is perfectly valid to skip some of the restores in the process:
you can always create additional snapshots and never use them.

For example, you can take two snapshots `s0` then `s1` of a stream
between write operations

    >>> stream = BitStream()
    >>> s0 = stream.save()
    >>> stream.write(b"A")
    >>> s1 = stream.save()
    >>> stream.write(b"B")
    >>> stream == BitStream(b"AB")
    True

restore `s1`

    >>> stream.restore(s1)
    >>> stream == BitStream(b"A")
    True

and then `s0`

    >>> stream.restore(s0)
    >>> stream == BitStream(b"")
    True

You can also make the same snapshots 

    >>> stream = BitStream()
    >>> s0 = stream.save()
    >>> stream.write(b"A")
    >>> s1 = stream.save()
    >>> stream.write(b"B")
    >>> stream == BitStream(b"AB")
    True

and directly restore `s0`

    >>> stream.restore(s0)
    >>> stream == BitStream(b"")
    True

but then `s1` cannot be used anymore

    >>> stream.restore(s1) # doctest: +ELLIPSIS
    Traceback (most recent call last):
    ...
    ValueError: ...


How does it Work?
--------------------------------------------------------------------------------

The main (private) attributes of a `BitStream` structure are:

  - an array of bytes: the raw data

  - read and write cursors: they locate the beginning and the end 
    of the stream in the bytes array.
 
When you read data from a stream, 
you shift the read cursor but the 
corresponding data is *not* deleted[^1] -- its is merely not accessible.
The `State` structure stores values 
of the read and write cursors; the call `state = stream.save()` produces 
a snapshot of the current cursor locations and
`stream.restore(state)` restores them.

[^1]: This is why the memory consumption increases if you write a lot
of data into a stream, *even if you read it!* The solution in this case is to
copy the stream and discard the original since the copy method discards 
write history.

