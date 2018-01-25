
Contributing
================================================================================

**Contributors:** <https://github.com/boisgera/bitstream/graphs/contributors>

Bitstream is developped on [GitHub](https://github.com/boisgera/bitstream).
To contribute, please [open an issue][issue] or [submit a pull request][PR]
for the code or documentation.
The following sections should help you to get started.

[GitHub]: https://github.com/boisgera/bitstream
[issue]: https://github.com/boisgera/bitstream/issues
[PR]: https://github.com/boisgera/bitstream/pulls

-----


Getting Started
--------------------------------------------------------------------------------

Follow the steps required to [install from sources](installation/#install-from-sources)
and make sure that you have installed all the developer dependencies 
(`pip install -r requirements-dev.txt`).


Run the Tests
--------------------------------------------------------------------------------

To run all the tests, type

     $ python test.py

[^1]: `pip install pyyaml`

If nothing happens, your version of bitstream is probably fine: 
all the code snippets
used [in the documentation](http://boisgera.github.io/bitstream/)
have been checked by [doctest] and have correct outputs.
To find out more about these tests, run

     $ python test.py -v

The bitstream project uses [Travis CI](https://travis-ci.org/) 
to run all the tests on each new commit. 
If you fork bitstream, make sure to [activate Travis CI](https://docs.travis-ci.com/user/getting-started/).
To add new tests, just [update the documentation](#documentation).

[doctest]: https://docs.python.org/2/library/doctest.html


Documentation
--------------------------------------------------------------------------------

The documentation is built with [MkDocs](http://www.mkdocs.org/) and its 
[Material](https://squidfunk.github.io/mkdocs-material/) theme.

The documentation sources are markdown files located 
in the [`mkdocs`](https://github.com/boisgera/bitstream/tree/master/mkdocs)
directory and assembled according to the configuration file 
[`mkdocs.yml`](https://github.com/boisgera/bitstream/blob/master/mkdocs.yml).
Build the docs[^build] with

    $ mkdocs build

This command outputs HTML documentation into the `docs` directory.

[^build]:
  For work in progress, use `mkdocs serve`: it creates a web server 
  that listens on `http://127.0.0.1:8000` and refreshes automatically
  the documentation when its source files change.
