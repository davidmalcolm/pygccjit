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

    .. py:method:: get_type(type_enum):

       Look up one of the standard types (see :py:class:`gccjit.TypeKind`)::

          int_type = ctxt.get_type(gccjit.TypeKind.INT)

       :param type_enum: Which type to lookup
       :type type_enum: :py:class:`gccjit.TypeKind`

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
     `gccjit.Location` instances.

  .. py:data:: DUMP_INITIAL_TREE

     If true, :py:meth:`gccjit.Context.compile` will dump its initial
     "tree" representation of your code to stderr (before any
     optimizations).

  .. py:data:: DUMP_INITIAL_GIMPLE

     If true, :py:meth:`gccjit.Context.compile` will dump the "gimple"
     representation of your code to stderr, before any optimizations
     are performed.  The dump resembles C code.

  .. py:data:: DUMP_GENERATED_CODE

     If true, :py:meth:`gccjit.Context.compile` will dump the final
     generated code to stderr, in the form of assembly language.

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

..
    def compile(self):
        """compile(self) -> Result"""
        cdef c_api.gcc_jit_result *c_result
        c_result = c_api.gcc_jit_context_compile(self._c_ctxt)
        if c_result == NULL:
            raise Exception(self.get_first_error())
        r = Result()
        r._set_c_ptr(c_result)
        return r

    def dump_to_file(self, path, update_locations):
        c_api.gcc_jit_context_dump_to_file(self._c_ctxt, path, update_locations)

    def get_first_error(self):
        cdef char *err = c_api.gcc_jit_context_get_first_error(self._c_ctxt)
        if err:
           return err
        return None

    def new_location(self, filename, line, column):
        """new_location(self, filename:str, line:int, column:int) -> Location"""
        cdef c_api.gcc_jit_location *c_loc
        c_loc = c_api.gcc_jit_context_new_location(self._c_ctxt, filename, line, column)
        loc = Location()
        loc._set_c_location(c_loc)
        return loc

    def new_global(self, Type type_, name, Location loc=None):
        """new_global(self, type_:Type, name:str, loc:Location=None) -> LValue"""
        c_lvalue = c_api.gcc_jit_context_new_global(self._c_ctxt,
                                                    get_c_location(loc),
                                                    type_._get_c_type(),
                                                    name)
        return LValue_from_c(c_lvalue)

    def new_array_type(self, Type element_type, int num_elements, Location loc=None):
        """new_array_type(self, element_type:Type, num_elements:int, loc:Location=None) -> Type"""
        c_type = c_api.gcc_jit_context_new_array_type(self._c_ctxt,
                                                      get_c_location(loc),
                                                      element_type._get_c_type(),
                                                      num_elements)
        return Type_from_c(c_type)

    def new_field(self, Type type_, name, Location loc=None):
        """new_field(self, type_:Type, name:str, loc:Location=None) -> Field"""
        c_field = c_api.gcc_jit_context_new_field(self._c_ctxt,
                                                  get_c_location(loc),
                                                  type_._get_c_type(),
                                                  name)
        field = Field()
        field._set_c_field(c_field)
        return field

    def new_struct(self, name, fields=None, Location loc=None):
        """new_struct(self, name:str, fields:list, loc:Location=None) -> Struct"""
        cdef int num_fields
        cdef c_api.gcc_jit_field **c_fields = NULL
        cdef Field field
        cdef c_api.gcc_jit_struct *c_struct

        if fields is None:
            c_struct = c_api.gcc_jit_context_new_opaque_struct(self._c_ctxt,
                                                               get_c_location(loc),
                                                               name)
        else:
            fields = list(fields)
            num_fields = len(fields)
            c_fields = \
              <c_api.gcc_jit_field **>malloc(num_fields * sizeof(c_api.gcc_jit_field *))

            if c_fields is NULL:
                raise MemoryError()

            for i in range(num_fields):
                field = fields[i]
                c_fields[i] = field._get_c_field()

            c_struct = c_api.gcc_jit_context_new_struct_type(self._c_ctxt,
                                                             get_c_location(loc),
                                                             name,
                                                             num_fields,
                                                             c_fields)
        py_struct = Struct()
        py_struct._set_c_struct(c_struct)
        free(c_fields)
        return py_struct

    def new_param(self, Type type_, name, Location loc=None):
        """new_param(self, type_:Type, name:str, loc:Location=None) -> Param"""
        c_result = c_api.gcc_jit_context_new_param(self._c_ctxt,
                                                   get_c_location(loc),
                                                   type_._get_c_type(),
                                                   name)
        return Param_from_c(c_result)

    def new_function(self, kind, Type return_type, name, params,
                     Location loc=None,
                     is_variadic=False):
        """new_function(self, kind:FunctionKind, return_type:Type, name:str, params:list, loc:Location=None, is_variadic=False) -> Function"""
        cdef Param param
        params = list(params)
        cdef int num_params = len(params)
        cdef c_api.gcc_jit_param **c_params = \
            <c_api.gcc_jit_param **>malloc(num_params * sizeof(c_api.gcc_jit_param *))
        if c_params is NULL:
            raise MemoryError()
        for i in range(num_params):
            param = params[i]
            c_params[i] = param._get_c_param()
        c_function = c_api.gcc_jit_context_new_function(self._c_ctxt,
                                                        get_c_location(loc),
                                                        kind,
                                                        return_type._get_c_type(),
                                                        name,
                                                        len(params),
                                                        c_params,
                                                        is_variadic)
        free(c_params)
        return Function_from_c(c_function)

    def get_builtin_function(self, name):
        """get_builtin_function(self, name:str) -> Function"""
        c_function = c_api.gcc_jit_context_get_builtin_function (self._c_ctxt, name)
        return Function_from_c(c_function)

    def zero(self, Type type_):
        """zero(self, type_:Type) -> RValue"""
        c_rvalue = c_api.gcc_jit_context_zero(self._c_ctxt,
                                              type_._get_c_type())
        return RValue_from_c(c_rvalue)

    def one(self, Type type_):
        """one(self, type_:Type) -> RValue"""
        c_rvalue = c_api.gcc_jit_context_one(self._c_ctxt,
                                             type_._get_c_type())
        return RValue_from_c(c_rvalue)

    def new_rvalue_from_double(self, Type numeric_type, double value):
        """new_rvalue_from_double(self, numeric_type:Type, value:float) -> RValue"""
        c_rvalue = c_api.gcc_jit_context_new_rvalue_from_double(self._c_ctxt,
                                                                numeric_type._get_c_type(),
                                                                value)
        return RValue_from_c(c_rvalue)

    def new_rvalue_from_int(self, Type type_, int value):
        """new_rvalue_from_int(self, type_:Type, value:int) -> RValue"""
        c_rvalue = c_api.gcc_jit_context_new_rvalue_from_int(self._c_ctxt,
                                                             type_._get_c_type(),
                                                             value)
        return RValue_from_c(c_rvalue)

    def new_rvalue_from_ptr(self, Type pointer_type, long value):
        c_rvalue = c_api.gcc_jit_context_new_rvalue_from_ptr(self._c_ctxt,
                                                             pointer_type._get_c_type(),
                                                             <void *>value)
        return RValue_from_c(c_rvalue)

    def null(self, Type pointer_type):
        """null(self, pointer_type:Type) -> RValue"""
        c_rvalue = c_api.gcc_jit_context_null(self._c_ctxt,
                                              pointer_type._get_c_type())
        return RValue_from_c(c_rvalue)

    def new_string_literal(self, char *value):
        """new_string_literal(self, value:str) -> RValue"""
        c_rvalue = c_api.gcc_jit_context_new_string_literal(self._c_ctxt,
                                                            value)
        return RValue_from_c(c_rvalue)

    def new_unary_op(self, op, Type result_type, RValue rvalue, Location loc=None):
        """new_unary_op(self, op:UnaryOp, result_type:Type, rvalue:RValue, loc:Location=None) -> RValue"""
        c_rvalue = c_api.gcc_jit_context_new_unary_op (self._c_ctxt,
                                                       get_c_location(loc),
                                                       op,
                                                       result_type._get_c_type(),
                                                       rvalue._get_c_rvalue())
        return RValue_from_c(c_rvalue)

    def new_binary_op(self, op, Type result_type, RValue a, RValue b, Location loc=None):
        """new_binary_op(self, op:BinaryOp, result_type:Type, a:RValue, b:RValue, loc:Location=None) -> RValue"""
        c_rvalue = c_api.gcc_jit_context_new_binary_op(self._c_ctxt,
                                                       get_c_location(loc),
                                                       op,
                                                       result_type._get_c_type(),
                                                       a._get_c_rvalue(),
                                                       b._get_c_rvalue())
        return RValue_from_c(c_rvalue)

    def new_comparison(self, op, RValue a, RValue b, Location loc=None):
        """new_comparison(self, op:Comparison, a:RValue, b:RValue, loc:Location=None) -> RValue"""
        c_rvalue = c_api.gcc_jit_context_new_comparison(self._c_ctxt,
                                                        get_c_location(loc),
                                                        op,
                                                        a._get_c_rvalue(),
                                                        b._get_c_rvalue())

        return RValue_from_c(c_rvalue)

    def new_child_context(self):
        """new_child_context(self) -> Context"""
        c_child_ctxt = c_api.gcc_jit_context_new_child_context(self._c_ctxt)
        if c_child_ctxt == NULL:
            raise Exception("Unknown error creating child context.")

        py_child_ctxt = Context(acquire=False)
        py_child_ctxt._c_ctxt = c_child_ctxt
        return py_child_ctxt

    def new_cast(self, RValue rvalue, Type type_, Location loc=None):
        """new_cast(self, rvalue:RValue, type_:Type, loc:Location=None) -> RValue"""
        c_rvalue = c_api.gcc_jit_context_new_cast(self._c_ctxt,
                                                  get_c_location(loc),
                                                  rvalue._get_c_rvalue(),
                                                  type_._get_c_type())
        return RValue_from_c(c_rvalue)


    def new_call(self, Function func, args, Location loc=None):
        """new_call(self, func:Function, args:list of RValue, loc:Location=None) -> RValue"""
        args = list(args)
        cdef int num_args = len(args)
        cdef c_api.gcc_jit_rvalue **c_args = \
            <c_api.gcc_jit_rvalue **>malloc(num_args * sizeof(c_api.gcc_jit_rvalue *))
        if c_args is NULL:
            raise MemoryError()

        cdef RValue rvalue
        for i in range(num_args):
            rvalue = args[i]
            c_args[i] = rvalue._get_c_rvalue()

        c_rvalue = c_api.gcc_jit_context_new_call(self._c_ctxt,
                                                  get_c_location(loc),
                                                  func._get_c_function(),
                                                  num_args,
                                                  c_args)

        free(c_args)
        return RValue_from_c(c_rvalue)

