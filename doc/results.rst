.. Copyright 2014-2015 David Malcolm <dmalcolm@redhat.com>
   Copyright 2014-2015 Red Hat, Inc.

   This is free software: you can redistribute it and/or modify it
   under the terms of the GNU General Public License as published by
   the Free Software Foundation, either version 3 of the License, or
   (at your option) any later version.

   This program is distributed in the hope that it will be useful, but
   WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
   General Public License for more details.

   You should have received a copy of the GNU General Public License
   along with this program.  If not, see
   <http://www.gnu.org/licenses/>.

Compilation results
===================

.. py:class:: gccjit.Result

   A :py:class:`gccjit.Result` encapsulates the result of compiling a
   :py:class:`gccjit.Context` in-memory, and the lifetimes of any
   machine code functions or globals that are within the result.

   .. py:method:: get_code(funcname)

      Locate the given function within the built machine code.

      Functions are looked up by name.  For this to succeed, a function
      with a name matching `funcname` must have been created on
      `result`'s context (or a parent context) via a call to
      :py:meth:`gccjit.Context.new_function` with `kind`
      :py:data:`gccjit.FunctionKind.EXPORTED`.

      .. error-handling?

      The returned value is an
      `int`, actually a pointer to the machine code within the
      address space of the process.  This will need to be wrapped up
      with `ctypes` to be callable::

         import ctypes

         # "[int] -> int" functype:
         int_int_func_type = ctypes.CFUNCTYPE(ctypes.c_int, ctypes.c_int)
         code = int_int_func_type(jit_result.get_code(b"square"))
         assert code(5) == 25

      The code has the same lifetime as the :py:class:`gccjit.Result`
      instance; the pointer becomes invalid when the result instance
      is cleaned up.
