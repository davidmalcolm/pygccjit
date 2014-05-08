.. Copyright 2014 David Malcolm <dmalcolm@redhat.com>
   Copyright 2014 Red Hat, Inc.

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

Compilation contexts
====================

.. py:class:: gccjit.Context

   The top-level of the API is the `gccjit.Context` class.

   A `gccjit.Context` instance encapsulates the state of a compilation.
   It goes through two states:

      * "initial", during which you can set up options on it, and add
        types, functions and code, using the API below.
        Invoking `compile` on it transitions it to the
        "after compilation" state.

      * "after compilation"

    .. py:method:: set_str_option(opt, val)

       Set a string option of the context; see :py:class:`gccjit.StrOption`
       for notes on the options and their meanings.

       :param opt: Which option to set
       :type opt: :py:class:`gccjit.StrOption`
       :param str val: The new value

    .. py:method:: set_bool_option(opt, val)

       Set a boolean option of the context; see :py:class:`gccjit.BoolOption`
       for notes on the options and their meanings.

       :param opt: Which option to set
       :type opt: :py:class:`gccjit.BoolOption`
       :param str val: The new value

    .. py:method:: set_int_option(opt, val)

       Set an integer option of the context; see :py:class:`gccjit.IntOption`
       for notes on the options and their meanings.

       :param opt: Which option to set
       :type opt: :py:class:`gccjit.IntOption`
       :param str val: The new value

    .. py:method:: get_type(type_enum)

       Look up one of the standard types (see :py:class:`gccjit.TypeKind`)::

          int_type = ctxt.get_type(gccjit.TypeKind.INT)

       :param type_enum: Which type to lookup
       :type type_enum: :py:class:`gccjit.TypeKind`

    .. py:method:: compile()

       :rtype: :py:class:`gccjit.Result`

    .. py:method:: dump_to_file(path, update_locations)

    .. py:method:: get_first_error()

    .. py:method:: new_location(filename, line, column)

       Make a :py:class:`gccjit.Location` representing a source location,
       for use by the debugger::

           loc = ctxt.new_location('web.js', 5, 0)

       .. note::

          You need to enable :py:data:`gccjit.BoolOption.DEBUGINFO` on the
          context for these locations to actually be usable by the debugger::

            ctxt.set_bool_option(gccjit.BoolOption.DEBUGINFO, True)

       :rtype: :py:class:`gccjit.Location`

    .. py:method:: new_global(Type type_, name, Location loc=None)

       :rtype: :py:class:`gccjit.LValue`

    .. py:method:: new_array_type(Type element_type, int num_elements, \
                                 Location loc=None)

       :rtype: :py:class:`gccjit.Type`

    .. py:method:: new_field(Type type_, name, Location loc=None)

       :rtype: :py:class:`gccjit.Field`

    .. py:method:: new_struct(name, fields=None, Location loc=None)

       :rtype: :py:class:`gccjit.Struct`

    .. py:method:: new_param(Type type_, name, Location loc=None)

       :rtype: :py:class:`gccjit.Param`

    .. py:method:: new_function(kind, Type return_type, name, params, \
                               Location loc=None, \
                               is_variadic=False)

       :rtype: :py:class:`gccjit.Function`

    .. py:method:: get_builtin_function(name)

       :rtype: :py:class:`gccjit.Function`

    .. py:method:: zero(type_)

       Given a :py:class:`gccjit.Type`, which must be a numeric type,
       get the constant 0 as a :py:class:`gccjit.RValue` of that type.

       :rtype: :py:class:`gccjit.RValue`

    .. py:method:: one(type_)

       Given a :py:class:`gccjit.Type`, which must be a numeric type,
       get the constant 1 as a :py:class:`gccjit.RValue` of that type.

       :rtype: :py:class:`gccjit.RValue`

    .. py:method:: new_rvalue_from_double(numeric_type, value)

       Given a :py:class:`gccjit.Type`, which must be a numeric type,
       get a floating-point constant as a :py:class:`gccjit.RValue` of
       that type.

       :rtype: :py:class:`gccjit.RValue`

    .. py:method:: new_rvalue_from_int(type_, value)

       Given a :py:class:`gccjit.Type`, which must be a numeric type,
       get an integer constant as a :py:class:`gccjit.RValue` of
       that type.

       :rtype: :py:class:`gccjit.RValue`

    .. py:method:: new_rvalue_from_ptr(pointer_type, value)

       Given a :py:class:`gccjit.Type`, which must be a pointer type,
       and an address, get a :py:class:`gccjit.RValue` representing
       that address as a pointer of that type::

          ptr = ctxt.new_rvalue_from_ptr(int_star, 0xDEADBEEF)

       :rtype: :py:class:`gccjit.RValue`

    .. py:method:: null(pointer_type)

       Given a :py:class:`gccjit.Type`, which must be a pointer type,
       get a :py:class:`gccjit.RValue` representing the `NULL` pointer
       of that type::

          ptr = ctxt.null(int_star)

       :rtype: :py:class:`gccjit.RValue`

    .. py:method:: new_string_literal(value)

       Make a :py:class:`gccjit.RValue` for the given string literal
       value (actually bytes)::

         msg = ctxt.new_string_literal(b'hello world\n')

       :param bytes value: the bytes of the string literal
       :rtype: :py:class:`gccjit.RValue`

    .. py:method:: new_unary_op(op, Type result_type, RValue rvalue, \
                               Location loc=None)

       :rtype: :py:class:`gccjit.RValue`

    .. py:method:: new_binary_op(op, Type result_type, RValue a, RValue b, \
                                Location loc=None)

       :rtype: :py:class:`gccjit.RValue`

    .. py:method:: new_comparison(op, RValue a, RValue b, Location loc=None)

       :rtype: :py:class:`gccjit.RValue`

    .. py:method:: new_child_context(self)

       :rtype: :py:class:`gccjit.Context`

    .. py:method:: new_cast(RValue rvalue, Type type_, Location loc=None)

       :rtype: :py:class:`gccjit.RValue`

    .. py:method:: new_call(Function func, args, Location loc=None)

       :rtype: :py:class:`gccjit.RValue`

String options
--------------
.. py:class:: gccjit.StrOption

    .. py:data:: PROGNAME

       The name of the program, for use as a prefix when printing error
       messages to stderr.  If `None`, or default, "libgccjit.so" is used.

Boolean options
---------------
.. py:class:: gccjit.BoolOption

  .. py:data:: DEBUGINFO

     If true, :py:meth:`gccjit.Context.compile` will attempt to do the right
     thing so that if you attach a debugger to the process, it will
     be able to inspect variables and step through your code.

     Note that you can't step through code unless you set up source
     location information for the code (by creating and passing in
     `gccjit.Location` instances).

  .. py:data:: DUMP_INITIAL_TREE

     If true, :py:meth:`gccjit.Context.compile` will dump its initial
     "tree" representation of your code to stderr (before any
     optimizations).

     Here's some sample output (from the `square` example)::

        <statement_list 0x7f4875a62cc0
           type <void_type 0x7f4875a64bd0 VOID
               align 8 symtab 0 alias set -1 canonical type 0x7f4875a64bd0
               pointer_to_this <pointer_type 0x7f4875a64c78>>
           side-effects head 0x7f4875a761e0 tail 0x7f4875a761f8 stmts 0x7f4875a62d20 0x7f4875a62d00

           stmt <label_expr 0x7f4875a62d20 type <void_type 0x7f4875a64bd0>
               side-effects
               arg 0 <label_decl 0x7f4875a79080 entry type <void_type 0x7f4875a64bd0>
                   VOID file (null) line 0 col 0
                   align 1 context <function_decl 0x7f4875a77500 square>>>
           stmt <return_expr 0x7f4875a62d00
               type <integer_type 0x7f4875a645e8 public SI
                   size <integer_cst 0x7f4875a623a0 constant 32>
                   unit size <integer_cst 0x7f4875a623c0 constant 4>
                   align 32 symtab 0 alias set -1 canonical type 0x7f4875a645e8 precision 32 min <integer_cst 0x7f4875a62340 -2147483648> max <integer_cst 0x7f4875a62360 2147483647>
                   pointer_to_this <pointer_type 0x7f4875a6b348>>
               side-effects
               arg 0 <modify_expr 0x7f4875a72a78 type <integer_type 0x7f4875a645e8>
                   side-effects arg 0 <result_decl 0x7f4875a7a000 D.54>
                   arg 1 <mult_expr 0x7f4875a72a50 type <integer_type 0x7f4875a645e8>
                       arg 0 <parm_decl 0x7f4875a79000 i> arg 1 <parm_decl 0x7f4875a79000 i>>>>>

  .. py:data:: DUMP_INITIAL_GIMPLE

     If true, :py:meth:`gccjit.Context.compile` will dump the "gimple"
     representation of your code to stderr, before any optimizations
     are performed.  The dump resembles C code::

       square (signed int i)
       {
         signed int D.56;

         entry:
         D.56 = i * i;
         return D.56;
       }

  .. py:data:: DUMP_GENERATED_CODE

     If true, :py:meth:`gccjit.Context.compile` will dump the final
     generated code to stderr, in the form of assembly language::

           .file    "fake.c"
           .text
           .globl    square
           .type    square, @function
       square:
       .LFB0:
           .cfi_startproc
           pushq    %rbp
           .cfi_def_cfa_offset 16
           .cfi_offset 6, -16
           movq    %rsp, %rbp
           .cfi_def_cfa_register 6
           movl    %edi, -4(%rbp)
       .L2:
           movl    -4(%rbp), %eax
           imull    -4(%rbp), %eax
           popq    %rbp
           .cfi_def_cfa 7, 8
           ret
           .cfi_endproc
       .LFE0:
           .size    square, .-square
           .ident    "GCC: (GNU) 4.9.0 20131023 (Red Hat 0.1-%{gcc_release})"
           .section    .note.GNU-stack,"",@progbits


  .. py:data:: DUMP_SUMMARY

     If true, :py:meth:`gccjit.Context.compile` will print information to stderr
     on the actions it is performing, followed by a profile showing
     the time taken and memory usage of each phase.

  .. py:data:: DUMP_EVERYTHING

     If true, :py:meth:`gccjit.Context.compile` will dump copious
     amount of information on what it's doing to various
     files within a temporary directory.  Use
     :py:data:`gccjit.BoolOption.KEEP_INTERMEDIATES` (see below) to
     see the results.  The files are intended to be human-readable,
     but the exact files and their formats are subject to change.

  .. py:data:: SELFCHECK_GC

     If true, libgccjit will aggressively run its garbage collector, to
     shake out bugs (greatly slowing down the compile).  This is likely
     to only be of interest to developers *of* the library.  It is
     used when running the selftest suite.

  .. py:data:: KEEP_INTERMEDIATES

     If true, the gccjit.Context will not clean up intermediate files
     written to the filesystem, and will display their location on stderr.

Integer options
---------------
.. py:class:: gccjit.IntOption

  .. py:data:: OPTIMIZATION_LEVEL

     How much to optimize the code.

     Valid values are 0-3, corresponding to GCC's command-line options
     -O0 through -O3.

     The default value is 0 (unoptimized).

Standard types
--------------

.. py:class:: gccjit.TypeKind

  .. py:data:: VOID

     C's "void" type.

  .. py:data:: VOID_PTR

     C's "void \*".

  .. py:data:: BOOL

     C++'s bool type; also C99's "_Bool" type, aka "bool" if using
     stdbool.h.

  .. py:data:: CHAR
  .. py:data:: SIGNED_CHAR
  .. py:data:: UNSIGNED_CHAR

     C's "char" (of some signedness) and the variants where the
     signedness is specified.

  .. py:data:: SHORT
  .. py:data:: UNSIGNED_SHORT

     C's "short" (signed) and "unsigned short".

  .. py:data:: INT
  .. py:data:: UNSIGNED_INT

     C's "int" (signed) and "unsigned int"::

          int_type = ctxt.get_type(gccjit.TypeKind.INT)

  .. py:data:: LONG
  .. py:data:: UNSIGNED_LONG

     C's "long" (signed) and "unsigned long".

  .. py:data:: LONG_LONG
  .. py:data:: UNSIGNED_LONG_LONG

     C99's "long long" (signed) and "unsigned long long".

  .. py:data:: FLOAT
  .. py:data:: DOUBLE
  .. py:data:: LONG_DOUBLE

     Floating-point types

  .. py:data:: CONST_CHAR_PTR

     C type: (const char \*)::

       const_char_p = ctxt.get_type(gccjit.TypeKind.CONST_CHAR_PTR)

  .. py:data:: SIZE_T

    The C "size_t" type.

  .. py:data:: FILE_PTR

    C type: (FILE \*)
