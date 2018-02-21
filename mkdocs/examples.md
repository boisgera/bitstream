
Examples
================================================================================

We provide the following examples of bitstream usage:

  - [Spoon](#spoon): build a translator between Brainfuck programs and Spoon
    programs.

  - [Wave](#wave): synthesize a pure tone and generate the corresponding
    WAVE audio file.

But first, as usual, let's start with

    >>> from bitstream import BitStream
    


Spoon
--------------------------------------------------------------------------------

[Spoon] is a derivative of the [Brainfuck] programming language.
Instead of the 8 ASCII symbols used by Brainfuck, it relies on
binary sequences to represent each instruction. 

[Spoon]: https://esolangs.org/wiki/Spoon
[Brainfuck]: https://en.wikipedia.org/wiki/Brainfuck

The source of the "Hello World!" program in Brainfuck is[^dtm]:

    >>> hello_world = "++++++++++[>+++++++>++++++++++>+++>+<<<<-]>++.>+.+++++++..+++.>++.<<+++++++++++++++.>.+++.------.--------.>+.>."

[^dtm]: You don't have to trust me on this, you may try this code online at <https://copy.sh/brainfuck/>.

The conversion between Brainfuck and Spoon is given by the table:

    >>> spoon = {
    ...   "+": "1",
    ...   "-": "000",
    ...   ">": "010",
    ...   "<": "011",
    ...   "[": "00100",
    ...   "]": "0011",
    ...   ".": "001010",
    ...   ",": "0010110",
    ... }

You may notice that the binary codes that correspond to symbols that frequently
appear in the `hello_world` program (such as `+`) are shorter than the others,
a nice property since it generates a compact representation of Spoon programs[^nac].

[^nac]: This is not a coincidence: Spoon has been designed as 
a [Huffman code](https://en.wikipedia.org/wiki/Huffman_coding)
based on the analysis of a representative collection of Brainfuck programs.

To create a bitstream that contains the Spoon translation of `hello_world`,
we may for each symbol in this program find the corresponding binary code 
in the `spoon` table, transform it into a list of bools and append this data 
to the stream.

    >>> stream = BitStream()
    >>> for symbol in hello_world:
    ...     code = spoon[symbol]
    ...     code_as_bools = [bool(int(char)) for char in code]
    ...     stream.write(code_as_bools)

Here is the result:

    >>> stream
    11111111110010001011111110101111111111010111010101101101101100000110101100101001010010101111111001010001010111001010010110010100110111111111111111110010100100010101110010100000000000000000000010100000000000000000000000000010100101001010010001010
    >>> len(hello_world) * 8
    888
    >>> len(stream)
    245

We now have of program of 245 bits instead of the 888 bits 
(111 bytes) of the original ASCII program. Not bad ...

-----

It's also pretty easy to perform the opposite operation, to translate Spoon into
Brainfuck. First, we can compute `noops`, the inverse of the `spoon` dictionary.

    >>> noops = {}
    >>> for symbol, code in spoon.items():
    ...     noops[code] = symbol
    >>> n = max(len(code) for code in noops)

Then we read bits one by one from the stream into a buffer and look at each 
stage if the buffer corresponds to a key in `noops`, translate this code,
empty the buffer and start again[^pfc].

    >>> src = ""
    >>> buffer = BitStream()
    >>> while len(stream) > 0:
    ...     if len(buffer) > n:
    ...         raise ValueError("invalid Spoon bitstream")
    ...     else:
    ...         buffer.write(stream.read(bool))
    ...         try:
    ...             src += noops[str(buffer)]
    ...             buffer = BitStream()
    ...         except KeyError:
    ...             pass
    >>> if len(buffer) > 0: # should be empty by now
    ...     raise ValueError("invalid Spoon bitstream")

[^pfc]: This approach -- without any lookahead -- is safe here because 
        this code is [prefix-free](https://en.wikipedia.org/wiki/Prefix_code).


We can then check that `src` and `hello_world` are the same program:

    >>> src == hello_world
    True



Wave
--------------------------------------------------------------------------------

What does it take to play a pure tone?
The synthesis of the data is quite easy: in the realm of digital audio,
sounds are just numbers and NumPy is up to the task.
The painful, low-level part of the process is to actually generate an
audio file in a format that your computer does understand. 
Fortunately, this is where bitstream can help[^r].

[^r]: Of course, there is a module in the Python standard library to
[read and write WAV files](https://docs.python.org/2/library/wave.html).
We just pretend that we're in the mood to reinvent this wheel and learn
something in the process.

Most of the audio file formats that you may know (MP3, AAC, FLAC, ALAC, etc.)
use compression to reduce file size; unfortunately
this feature leads to rather complex formats. 
Therefore, we are going to output [WAVE](https://en.wikipedia.org/wiki/WAV) 
files instead, which are typically uncompressed.
 
The [WAVE PCM soundfile format] webpage[^cs] is a great source of information
about the format. We will use it to design our code; please have a look at it!
Here is its high-level description:

[^cs]: by [Craig Sapp](mailto:craig@ccrma.stanford.edu) from the
       [Center for Computer Research in Music and Acoustics](https://ccrma.stanford.edu/):

> The WAVE file format is a subset of Microsoft's RIFF specification for the 
> storage of multimedia files. 
> A RIFF file starts out with a file header followed by a sequence of data 
> chunks. 
> A WAVE file is often just a RIFF file with a single "WAVE" chunk which 
> consists of two sub-chunks -- a "fmt " chunk specifying the data format 
> and a "data" chunk containing the actual sample data. 


[WAVE PCM soundfile format]: http://soundfile.sapp.org/doc/WaveFormat/

First, we import NumPy (and globally the integer types that we need).

    >>> import numpy as np
    >>> from numpy import uint8, uint16, uint32, int16

We use NumPy to produce 3 seconds of a pure tone with frequency 440 Hz
(A4) at a sampling rate of 44.1 kHz 
(the audio CD standard).

    >>> # Generate a waveform (pure tone)
    >>> df = 44100
    >>> dt = 1.0 / df
    >>> T = 3.0
    >>> t = np.r_[0.0:T:dt]
    >>> f = 440.0
    >>> data = np.sin(2 * np.pi * f * t)

In this description, every sample is a floating-point number that requires 
64 bits. The typical WAVE file requires 16-bit integer data instead, so we
perform the (lossy) conversion:

    >>> # Quantize the floating-point data
    >>> ones_ = np.ones_like(data)
    >>> low  = (-2**15    ) * ones_
    >>> high = ( 2**15 - 1) * ones_
    >>> data = np.clip(2**15 * data, low, high)
    >>> data = np.round(data).astype(np.int16) 

Since WAVE files use a [little-endian](https://en.wikipedia.org/wiki/Endianness)
representation every numeric value
and since bitstream is [big-endian](https://en.wikipedia.org/wiki/Endianness)
by default, we define a small function to
help us perform the change automatically, using the `newbyteorder` 
method of NumPy.

    >>> # Stream endianness helper 
    >>> stream = BitStream()
    >>> def write(datum, type=None):
    ...     if type and issubclass(type, np.integer):
    ...         datum = type(datum).newbyteorder()
    ...     stream.write(datum, type)

The rest of the work is a straightforward translation of the 
[specification][WAVE PCM soundfile format]: first we write the main chunk

    >>> # "RIFF" Chunk Descriptor
    >>> chunk_size = 36 + 2 * len(data)  # size of the chunk after "RIFF"
    >>> 
    >>> write(b"RIFF"           )
    >>> write(chunk_size, uint32)
    >>> write(b"WAVE"           )

then the format subchunk

    >>> # "fmt" SubChunk
    >>> subchunk1_size  = 16      # size in bytes of the subchunk after "fmt " 
    >>> audio_format    = 1       # PCM data
    >>> num_channels    = 1       # mono
    >>> byte_rate       = 2 * df
    >>> block_align     = 2       # number of bytes for one sample (all channels)
    >>> bits_per_sample = 16
    >>> 
    >>> write(b"fmt "                )
    >>> write(subchunk1_size , uint32)
    >>> write(audio_format   , uint16)
    >>> write(num_channels   , uint16)
    >>> write(df             , uint32)
    >>> write(byte_rate      , uint32)
    >>> write(block_align    , uint16)
    >>> write(bits_per_sample, uint16)

and finally the data subchunk

    >>> # "data" SubChunk
    >>> subchunk2_size = 2 * len(data)  # size in bytes of the subchunk after "data"
    >>>  
    >>> write(b"data"               )
    >>> write(subchunk2_size, uint32)
    >>> write(data          ,  int16)

and that's it! `stream` holds the content of our WAVE file;
all we have to do is to read it as a string that we write into an 
actual file.

    >>> # Generate the WAVE file
    >>> wave_bytes = stream.read(bytes)
    >>> wave_file = open("output.wav", "wb")
    >>> _ = wave_file.write(wave_bytes)
       
You can now listen to the sound in `output.wav` with your favorite music player.

For the sake of consistency, let's make sure that you and I have the same 
contents:

    >>> import hashlib
    >>> m = hashlib.md5()
    >>> m.update(wave_bytes)
    >>> m.digest() # doctest: +BYTES
    b'\xb0\xcf\x0e8\x150\x1fV \x86\x9e2\xdf\xfb\x1d\xec'

