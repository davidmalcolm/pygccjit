Python bindings for libgccjit.so (using Cython)

Tested with Python 2.7 and 3.2

GPLv3 or later.

JIT-compiled functions are wrapped up as `ctypes` callables.

Prebuilt HTML documentation can be seen at
http://pygccjit.readthedocs.org/en/latest/index.html

Caveats
^^^^^^^
* Most of the API is wrapped, but not all.

* Currently the ctypes hack forces all functions to be of type:

     int foo(int);
