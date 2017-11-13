
Contributing
================================================================================

**TODO:**

  - contribution process (via GitHub)

  - build the documentation

  - build from the sources

  - run the tests

----

Bitstream targets [Python 2.7][], you will need to install it first.

**TODO:** move NumPy dependency here (? Dunno ...), talk about Linux-only platform.


  - **Install from source:** the releases of Bitstream are available
    on the [Python Package Index (PyPi)][PyPi]. Once you have 
    downloaded and unpacked the archive, to build the Bitstream module, 
    you need [setuptools][].
    You also need to install the [NumPy][] package, version 1.6.1 or later.

    **TODO: test if numpy is automatically download if needed**.
 
    Then, as root, execute

        $ python setup.py install

  - **Hack with git:** to experiment with the latest version of Bitstream, 
    clone the GitHub repository:

        $ git clone git://github.com/boisgera/bitstream.git

    To actually build the module, you will need everything you need to build
    from source and will execute the same command. If in addition, you want
    to edit the source files, you will also need the [Cython][] compiler, 
    version 0.15.1 or later and will execute instead:

        $ python setup.py install --cython

[Python 2.7]: http://www.python.org/download/releases/2.7
[pip]: https://pypi.python.org/pypi/pip
[virtualenv]: https://pypi.python.org/pypi/virtualenv
[PyPi]: https://pypi.python.org/pypi/bitstream/
[GitHub]: https://github.com/boisgera/bitstream
[setuptools]: https://pypi.python.org/pypi/setuptools
[distribute]: http://pythonhosted.org/distribute/
[NumPy]: http://www.numpy.org

