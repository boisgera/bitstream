
Python 2
---------------------------------------------------------------------------------

Bitstream supports Python 2.7.
Make sure that the [pip] package installer is available 
for this version of the interpreter

    $ pip --version
    pip 9.0.1 from /usr/local/lib/python2.7/dist-packages (python 2.7)

and install wish

    $ pip install wish

[pip]: https://packaging.python.org/tutorials/installing-packages/#install-pip-setuptools-and-wheel


Python 3
--------------------------------------------------------------------------------

!!! warning
    Wish does not support Python 3 (yet).

If you want to install bitstream (for Python 2) 
but `pip` refers to your Python 3 interpreter

    $ pip --version
    pip 9.0.1 from /usr/local/lib/python3.5/dist-packages (python 3.5)

then you may have a version of pip for Python 2 installed.
It may be named `pip2` or `pip2.7`; you can use it to install wish.
Otherwise, refer to your Python 2 interpreter explicitly: 
if it is named `python`

    $ python --version
    Python 2.7.12

then install pip for Python 2 with

    $ python -m pip install --upgrade pip

and finally install bitstream

    $ python -m pip install bitstream


