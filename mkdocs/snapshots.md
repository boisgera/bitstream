
Snapshots (Bitstream state)
================================================================================

(random thought for the moment, fondations for the design of snapshots:)

**TODO:** sort doc material vs dev comments, dispatch, polish.

terms: snapshot (state ?), save, restore.


**Goals:** 

  - for the implementation and error API point of view: give a mechanism to roll
    back all operations that may end up with a "corrupted" stream (stream
    content has changed but cannot deliver what the read asked for), so
    that the mere error scheme that we have now on reader can be upgraded
    to a real exception handling mechansim: if a read fails, the stream
    state hasn't changed.

  - offer the user with read-only and on-demand roll-back features.


Add `save` (returns a (read_offset, write_offset) state) and `restore`
(with state as an argument) or `load` ? We leverage the fact in our
stream model, the data is not immutable, but no information is lost,
only added at the end, so we may always roll back if we need too.

These two methods shall enable a true exception management (not mere
errors, when shit happens, we still have a usable state), AND at the
same time, read-only streams. Maybe higher-level constructs (with
context manager ?) could be useful here to exploit those two schemes.
       
UPDATE: if we want the save / restor NOT TO CRASH, we have to ensure of two
things

  - first that the state stores the id of the stream ... you can't
    restore a state that was not created by you.

  - secondly, as restore + write break the immutability of the stream,
    save/restore pairs should only be applied in reverse order, with
    possible drops in the restore. That should be check by the stream.
    What I mean is that save 1, save 2, restore 2, restore 1 os OK,
    S1, S2, R1 is ok, but S1, S2, R1, S2 is not.

Design: `State` class with ref to the stream attribute, `read_offset`,
`write_offset`, implements the comparison (?). Not that simple. The idea
behind the comparison is that you should always be able to restore an
OLDER snapshot but actually if you think of it, that's older in the 
story of emission of snapshots. So you also have to embed a snapshot 
number and base your comparison on that. As a consequence, bitstream
instances have nothing to store but a snapshot number (the number of
the snapshot that was emitted, or 0 if no snapshot was). No, this is
more complex, requires some thinking. Need to track all restorable
states in the stream ? Maybe ...

**TODO.** basic doctest.

    >>> stream = BitStream()
    >>> s0 = stream.save()
    >>> stream.write("A")
    >>> s1 = stream.save()
    >>> stream.write("B")
    >>> s2 = stream.save()
    >>> stream.restore(s1)
    >>> stream == BitStream("A")
    True
    >>> stream.restore(s2) # doctest: +ELLIPSIS
    Traceback (most recent call last):
    ...
    ValueError: ...
    >>> stream.write("C")
    >>> stream == BitStream("AC")
    True
    >>> s3 = stream.save()
    >>> stream.restore(s1)
    >>> stream == BitStream("A")
    True
    >>> stream.restore(s0)
    >>> stream == BitStream("")
    True

Most useful patterns: 

**Avoid copies.** Do read/write stuff on a stream and when you're done, 
restore the original stream intact. Here the snapshot approach avoids a 
copy of the bitstream. The pattern is a `try/finally` with a snapshot
restore in the finally clause.

    >>> stream = BitStream("ABC")
    >>> snapshot = stream.save()
    >>> try:
    ...     # turn "ABC" into "BCD"
    ...     _ = stream.read(str, 1)
    ...     stream.write("D")
    ... finally:
    ...     stream.restore(snapshot)
    >>> stream == BitStream("ABC")
    True

If an exception can be raised during the read/write, the stream is still 
restored in the original state.

    >>> from bitstream import ReadError
    >>> stream = BitStream("ABC")
    >>> snapshot = stream.save()
    >>> try:
    ...     # read too much data
    ...     _ = stream.read(str, 4)
    ... except ReadError:
    ...     pass
    ... finally:
    ...     stream.restore(snapshot)
    >>> stream == BitStream("ABC")
    True

Remark: the pattern breaks if during the actions, an earlier snapshot is restored.

**Support true exceptions in readers.** Som reading actions may fail, but you
are not able to tell beforehand, you have to start a sequence of smaller
reads before you know of the big read call is going to work. A reader with a
proper exception support will restore the orginal state of the stream before 
raising the exception if something goes wrong. Typically, that means a reader
code with the structure:

    >>> def reader(stream, n=None):
    ...     snapshot = stream.save()
    ...     try:
    ...         pass # do what you have to do.
    ...     except ReadError: 
    ...         stream.restore(snapshot)
    ...         raise

Make convenience functions (with context managers) for those use cases ?
For the "light-weight copy" that would be easy (under what name ?) but 
for the reader, that's not obvious, the reader developer may be willing
to analyze the error and customize the error message before a re-raise ...
