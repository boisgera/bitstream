

Bitstream supports Python 2.7 on Linux, Windows and MacOS.

Installation
--------------------------------------------------------------------------------

Check the following prerequisites 

??? note "Pip"
    The pip package installer should be available for Python 2.7

        $ pip --version
        pip 9.0.1 from /usr/local/lib/python2.7/dist-packages (python 2.7)

    Otherwise follow these [installation instructions][install-pip].

??? note "NumPy"
    Bitstream depends on the [NumPy] package; install it if necessary:

            $ pip install numpy

??? note "C compiler"
    You need a C compiler pip can work with. 
    On Windows, you may need to install the 
    [Microsoft Visual C++ Compiler for Python 2.7][MSVC].

then install bitstream:

    $ pip install bitstream

[pip]: https://pypi.python.org/pypi/pip
[install-pip]: https://pip.pypa.io/en/stable/installing/
[NumPy]: http://www.numpy.org/
[MSVC]: https://www.microsoft.com/en-us/download/details.aspx?id=44266



Troubleshooting
--------------------------------------------------------------------------------

??? warning "What if pip is available but associated to Python 3?"

    If `pip` refers to your Python 3 interpreter

        $ pip --version
        pip 9.0.1 from /usr/local/lib/python3.5/dist-packages (python 3.5)

    you may still have a version of pip for Python 2.7 installed.
    It may be named `pip2` or `pip2.7`; you can use it to install bitstream.
    Otherwise, refer to your Python 2.7 interpreter explicitly: 
    if it is named `python`

        $ python --version
        Python 2.7.12

    then install pip for Python 2.7 with

        $ python -m pip install --upgrade pip

    and finally install bitstream

        $ python -m pip install bitstream


