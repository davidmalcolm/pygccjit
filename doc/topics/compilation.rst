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

Compiling a context
===================

Once populated, a :py:class:`gccjit.Context` can be compiled to
machine code, either in-memory via :py:meth:`gccjit.Context.compile` or
to disk via :py:meth:`gccjit.Context.compile_to_file`.

You can compile a context multiple times (using either form of
compilation), although any errors that occur on the context will
prevent any future compilation of that context.

In-memory compilation
*********************

.. py:method:: gccjit.Context.compile(self)

       :rtype: :py:class:`gccjit.Result`

   This calls into GCC and builds the code, returning a
   :py:class:`gccjit.Result`.

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

.. TODO: gcc_jit_result_get_global

Ahead-of-time compilation
*************************

Although libgccjit is primarily aimed at just-in-time compilation, it
can also be used for implementing more traditional ahead-of-time
compilers, via the :py:meth:`gccjit.Context.compile_to_file`
API entrypoint.

.. py:method:: gccjit.Context.compile_to_file(self, kind, path)

   Compile the context to a file of the given
   kind::

     ctxt.compile_to_file(gccjit.OutputKind.EXECUTABLE,
                          'a.out')

   :py:meth:`gccjit.Context.compile_to_file` ignores the suffix of
   ``path``, and insteads uses `kind` to decide what to do.

   .. note::

      This is different from the ``gcc`` program, which does make use of the
      suffix of the output file when determining what to do.

   The available kinds of output are:

   ============================================  ==============
   Output kind                                     Typical suffix
   ============================================  ==============
   :py:data:`gccjit.OutputKind.ASSEMBLER`        .s
   :py:data:`gccjit.OutputKind.OBJECT_FILE`      .o
   :py:data:`gccjit.OutputKind.DYNAMIC_LIBRARY`  .so or .dll
   :py:data:`gccjit.OutputKind.EXECUTABLE`       None, or .exe
   ============================================  ==============

.. py:class:: gccjit.OutputKind

   .. py:data:: ASSEMBLER

      Compile the context to an assembler file.

   .. py:data:: OBJECT_FILE

      Compile the context to an object file.

   .. py:data:: DYNAMIC_LIBRARY

      Compile the context to a dynamic library.

      There is currently no support for specifying other libraries to link
      against.

   .. py:data:: EXECUTABLE

      Compile the context to an executable.

      There is currently no support for specifying libraries to link
      against.
