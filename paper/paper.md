---
title: 'Bitstream -- Binary Data for Humans'
author: Sébastien Boisgérault, MINES ParisTech
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
date: 13 November 2017
bibliography: bibliography.json
---

# Summary

[Bitstream] [@bitstream] is a Python library to manage binary data 
as bitstreams.
Bitstreams are sequential: you can only write data at the end of
a stream and read data at its beginning, in the same order.
This simple model lends itself to a high-level programming interface
which is mostly self-explanatory.

[Bitstream]: https://github.com/boisgera/bitstream

This library supports out of the box data types from Python and NumPy: 
ASCII strings, (arrays of) booleans, fixed-size integers, floating-point numbers,
etc.
You can also define and register custom (even parametrized) types and 
their binary representation,
and then use them with the same interface. 
As its name implies, bitstream can work at the bit-level,
thus data types that don't fit in a entire number of bytes are
managed seamlessly.
If you reach the limits of the purely sequential model,
the library supports creation and restoration of stream snapshots;
this "time machine" scheme is more than adequate for many use cases
(header lookahead, decoders with strong exception safety, etc.).
And since bitstream is a Python C extension, it is fast enough for many use cases.

The design of bitstream was initially driven by the development of 
a "Digital Audio Coding" graduate course at MINES ParisTech University
[@S1916; @DAC].
In this context, which mixes information theory, binary formats and numeric data, 
the bitstream abstraction works really well.
A simple interface was required to replace pseudo-code
with actual code, bridging the gap between lectures and lab sessions.
Since none of the Python libraries we were aware of 
[@struct; @array; @bitstring; @bitarray, etc.] supported
the feature set described above, bitstream was born.

The library later proved to be useful to prototype and document
quickly classic and experimental binary formats and codecs.
It was integrated as a component of the Python [`audio`] package 
and used by audio coding applications,
such as [`audio.wave`], a reader and writer of WAVE files [see e.g. @WAVE]
integrated with NumPy and [`audio.shrink`], an experimental lossless codec 
inspired by SHORTEN [@Rob94].

[`audio`]: https://pypi.python.org/pypi/audio
[`audio.wave`]: https://github.com/boisgera/audio.wave
[`audio.shrink`]: https://github.com/boisgera/audio.shrink

[struct]: https://docs.python.org/2/library/struct.html
[array]: https://docs.python.org/2/library/array.html
[bitstring]: https://pypi.python.org/pypi/bitstring
[bitarray]: https://pypi.python.org/pypi/bitarray

# References
