---
title: 'Bitstream -- Binary Data for Humans'
author: Sébastien Boisgérault, MINES ParisTech
tags:
  - binary data
  - data compression
authors:
 - name: Sébastien Boisgérault
   orcid: 0000-0003-4685-8099
   affiliation: 1
affiliations:
 - name: MINES ParisTech, PSL Research University, Centre for robotics
   index: 1
date: 13 November 2017
bibliography: bibliography.bib
---

# Summary

Audiophiles are familiar with multiple digital
audio file formats (WAV, MP3, AAC, ALAC, FLAC, etc.) and generally 
know that this multiplicity is justified by different trade-offs and features
(in terms of quality, compression rate, complexity, for example).
The same logic drives the research for new binary formats
in many contexts.
Such research goes through an experimental phase where the development of
codecs -- the software that transforms back and forth the original data 
into binary data -- is required for any theoretical design.
Any tool which can simplify and speed up the prototyping 
of such codecs therefore improves significantly this iterative process.

In this context, [Bitstream] 
[@bitstream] provides a Python library with a 
simple, high-level and customizable programming interface 
to manage binary data. 
Many classic but menial tasks usually required
are automatically taken care of under the hood.

The cornerstone of the library is the use of the "bitstream" abstraction.
The "stream" part means that we use a simple model where 
one can only write data at one end of the binary structure 
and read data at the other end, in the same order. 
The "bit" part means that the library can work seamlessly 
with individual bits and not merely bytes, a feature frequently
required by lossless data compression schemes. 
Bitstream supports out of the box data types from Python and NumPy: 
ASCII strings, (arrays of) booleans, fixed-size integers, floating-point numbers,
etc.
One can also define and register custom (even parametrized) types and 
their binary representation,
and then use them with the same interface. 
Since the library supports creation and restoration of stream snapshots,
it's possible to go beyond the stream model when necessary;
this "time machine" scheme is more than adequate for many use cases
(header lookahead, decoders with strong exception safety, etc.).
And since bitstream is a Python C extension, it is fast enough for many
applications.

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

[Bitstream]: https://github.com/boisgera/bitstream
[`audio`]: https://pypi.python.org/pypi/audio
[`audio.wave`]: https://github.com/boisgera/audio.wave
[`audio.shrink`]: https://github.com/boisgera/audio.shrink

[struct]: https://docs.python.org/2/library/struct.html
[array]: https://docs.python.org/2/library/array.html
[bitstring]: https://pypi.python.org/pypi/bitstring
[bitarray]: https://pypi.python.org/pypi/bitarray
 
# References

