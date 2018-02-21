#!/usr/bin/env python

# Python Standard Library
from __future__ import print_function
import doctest
import sys

# Third-Party Libraries
import yaml

# ------------------------------------------------------------------------------

mkdocs_pages = yaml.load(open("mkdocs.yml"))["pages"]
mkdocs_files = ["mkdocs/" + list(item.values())[0] for item in mkdocs_pages]
extra_testfiles = []

test_files = mkdocs_files + extra_testfiles

fails = 0
tests = 0
for filename in test_files:
    _fails, _tests = doctest.testfile(filename, module_relative=False)
    fails += _fails
    tests += _tests

verbose = "-v" in sys.argv or "--verbose" in sys.argv
if verbose:
   print()
   print(60*"-")
   print("Test Suite Report:", end="")
   print("{0} failures / {1} tests".format(fails, tests))
   print(60*"-")
if fails:
    sys.exit(1)
 
