---
title: 'Bitstream -- Binary Data for Humans'
tags:
  - binary data
  - data compression
  - audio coding
authors:
 - name: Sébastien Boisgérault
   orcid: 0000-0003-4685-8099
   affiliation: 1
affiliations:
 - name: MINES ParisTech, PSL Research University, Center for robotics
   index: 1
date: 9 November 2017
bibliography: paper.yaml
---

# Summary

[Bitstream] [@bitstream] is a Python library that deals with binary data stored in streams.
Streams are sequential: you can only read data at the beginning of a 
stream and write data at its end.
This simple model lends itself to a high-level programming interface
which is mostly self-explanatory.

[Bitstream]: https://github.com/boisgera/bitstream

The library supports out of the box many common data types from Python and NumPy: 
ASCII strings, (arrays of) booleans, fixed-size integers, floating-point numbers,
etc. And since it's a Python C extension, it should be fast enough.

You can also define and register custom (even parametrized) types and 
their binary representation,
and then use them with the same interface. 
As its name implies, bitstream can work at the bit-level,
thus data types that don't fit in a entire number of bytes are
managed seamlessly.
And if you reach the limits of the purely sequential model,
the library supports creation and restoration of stream snapshots;
this "time machine" scheme is more than adequate for many use cases
(header lookahead, decoders with strong exception safety, etc.).

The design of bitstream was driven by the development of 
a "Digital Audio Coding" course at MINES ParisTech University
[@S1916; @DAC], a context where the bitstream model works really well;
a simple interface was required to replace pseudo-code
with actual code, bridging the gap between lectures and lab sessions.
Since none of the Python libraries we were aware of 
[@struct; @bitstring; @bitarray, etc.] supported
the full feature set described above, bitstream was born.
Later, it was integrated as a component of the Python [`audio`] package 
and used by several audio coding applications,
such as [`audio.wave`], a reader and writer of WAVE files [see e.g. @WAVE]
integrated with NumPy and [`audio.shrink`], a codec similar to SHORTEN
[@Rob94], the ancestor of modern lossless audio codecs.

[`audio`]: https://pypi.python.org/pypi/audio
[`audio.wave`]: https://github.com/boisgera/audio.wave
[`audio.shrink`]: https://github.com/boisgera/audio.shrink

[struct]: https://docs.python.org/2/library/struct.html
[bitstring]: https://pypi.python.org/pypi/bitstring
[bitarray]: https://pypi.python.org/pypi/bitarray

# References
