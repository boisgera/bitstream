#!/usr/bin/env python

# Python Standard Library
from __future__ import print_function
import doctest
import sys

# Third-Party Libraries
import yaml


# Doctest Helper
# ------------------------------------------------------------------------------
# The issue: b'A' displays as b'A' in Python 3 but as 'A' in Python 2.
# The solution: write your doctests with the 'b' prefix
# -- that is, target Python 3 -- but use the doctest directive BYTES 
# that we introduce in this section to automatically tweak them for Python 2.

# declare 'BYTES' 
doctest.BYTES = doctest.register_optionflag("BYTES")
doctest.__all__.append("BYTES")
doctest.COMPARISON_FLAGS = doctest.COMPARISON_FLAGS | doctest.BYTES

_doctest_OutputChecker = doctest.OutputChecker

class BytesOutputChecker(_doctest_OutputChecker):
    def check_output(self, want, got, optionflags):
        super_check_output = _doctest_OutputChecker.check_output
        if (optionflags & doctest.BYTES) and sys.version_info[0] == 2:
            want = want[1:] # strip the 'b' prefix from the expected result
        return super_check_output(self, want, got, optionflags)

# monkey-patching
doctest.OutputChecker = BytesOutputChecker


# Test Files
# ------------------------------------------------------------------------------
mkdocs_pages = yaml.load(open("mkdocs.yml"), Loader=yaml.FullLoader)["pages"]
mkdocs_files = ["mkdocs/" + list(item.values())[0] for item in mkdocs_pages]
extra_testfiles = []
test_files = mkdocs_files + extra_testfiles


# Run the Tests
# ------------------------------------------------------------------------------
verbose = "-v" in sys.argv or "--verbose" in sys.argv

fails = 0
tests = 0
for filename in test_files:
    # TODO enable verbose mode in each testfile call if appropriate
    options = {"module_relative": False, "verbose": verbose}
    _fails, _tests = doctest.testfile(filename, **options)
    fails += _fails
    tests += _tests

if fails > 0 or verbose:
   print()
   print(60*"-")
   print("Test Suite Report:", end="")
   print("{0} failures / {1} tests".format(fails, tests))
   print(60*"-")
if fails:
    sys.exit(1)
 
