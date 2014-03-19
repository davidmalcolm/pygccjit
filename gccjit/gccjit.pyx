#   Copyright 2013 David Malcolm <dmalcolm@redhat.com>
#   Copyright 2013 Red Hat, Inc.
#   Copyright 2014 Simon Feltman <s.feltman@gmail.com>
#
#   This is free software: you can redistribute it and/or modify it
#   under the terms of the GNU General Public License as published by
#   the Free Software Foundation, either version 3 of the License, or
#   (at your option) any later version.
#
#   This program is distributed in the hope that it will be useful, but
#   WITHOUT ANY WARRANTY; without even the implied warranty of
#   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
#   General Public License for more details.
#
#   You should have received a copy of the GNU General Public License
#   along with this program.  If not, see
#   <http://www.gnu.org/licenses/>.

from libc.stdlib cimport malloc, free
cimport gccjit as c_api


cdef class Context:
    cdef c_api.gcc_jit_context* _c_ctxt

    def __cinit__(self, acquire=True):
        if acquire:
            self._c_ctxt = c_api.gcc_jit_context_acquire()
        else:
            self._c_ctxt = NULL

    def __dealloc__(self):
        c_api.gcc_jit_context_release(self._c_ctxt)

    def set_str_option(self, opt, val):
        """set_int_option(self, opt:StrOption, val:str)"""
        c_api.gcc_jit_context_set_str_option(self._c_ctxt, opt, val)

    def set_bool_option(self, opt, val):
        """set_int_option(self, opt:BoolOption, val:bool)"""
        c_api.gcc_jit_context_set_bool_option(self._c_ctxt, opt, val)

    def set_int_option(self, opt, val):
        """set_int_option(self, opt:IntOption, val:int)"""
        c_api.gcc_jit_context_set_int_option(self._c_ctxt, opt, val)

    def get_type(self, type_enum):
        """get_type(self, type_enum:TypeKind) -> Type"""
        return Type_from_c(c_api.gcc_jit_context_get_type(self._c_ctxt, type_enum))

    def get_int_type(self, num_bytes, is_signed):
        """get_int_type(self, num_bytes:int, is_signed:bool) -> Type"""
        return Type_from_c(c_api.gcc_jit_context_get_int_type(self._c_ctxt, num_bytes, is_signed))

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
        return c_api.gcc_jit_context_get_first_error(self._c_ctxt)

    def new_location(self, filename, line, column):
        """new_location(self, filename:str, line:int, column:int) -> Location"""
        cdef c_api.gcc_jit_location *c_loc
        c_loc = c_api.gcc_jit_context_new_location(self._c_ctxt, filename, line, column)
        loc = Location()
        loc._c_location = c_loc
        return loc

    def new_global(self, Type type_, name, Location loc=None):
        """new_global(self, type_:Type, name:str, loc:Location=None) -> LValue"""
        c_lvalue = c_api.gcc_jit_context_new_global(self._c_ctxt,
                                                    get_c_location(loc),
                                                    type_._c_type,
                                                    name)
        return LValue_from_c(c_lvalue)

    def new_array_type(self, Type element_type, int num_elements, Location loc=None):
        """new_array_type(self, element_type:Type, num_elements:int, loc:Location=None) -> Type"""
        c_type = c_api.gcc_jit_context_new_array_type(self._c_ctxt,
                                                      get_c_location(loc),
                                                      element_type._c_type,
                                                      num_elements)
        return Type_from_c(c_type)

    def new_field(self, Type type_, name, Location loc=None):
        """new_field(self, type_:Type, name:str, loc:Location=None) -> Field"""
        c_field = c_api.gcc_jit_context_new_field(self._c_ctxt,
                                                  get_c_location(loc),
                                                  type_._c_type,
                                                  name)
        field = Field()
        field._c_field = c_field
        return field

    def new_struct(self, name, fields, Location loc=None):
        """new_struct(self, name:str, fields:list, loc:Location=None) -> Struct"""
        fields = list(fields)
        cdef int num_fields = len(fields)
        cdef c_api.gcc_jit_field **c_fields = \
            <c_api.gcc_jit_field **>malloc(num_fields * sizeof(c_api.gcc_jit_field *))

        if c_fields is NULL:
            raise MemoryError()

        cdef Field field
        for i in range(num_fields):
            field = fields[i]
            c_fields[i] = field._c_field

        c_struct = c_api.gcc_jit_context_new_struct_type(self._c_ctxt,
                                                         get_c_location(loc),
                                                         name,
                                                         num_fields,
                                                         c_fields)
        py_struct = Struct()
        py_struct._c_struct = c_struct
        free(c_fields)
        return py_struct

    def new_param(self, Type type_, name, Location loc=None):
        """new_param(self, type_:Type, name:str, loc:Location=None) -> Param"""
        c_result = c_api.gcc_jit_context_new_param(self._c_ctxt,
                                                   get_c_location(loc),
                                                   type_._c_type,
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
            c_params[i] = param._c_param
        c_function = c_api.gcc_jit_context_new_function(self._c_ctxt,
                                                        get_c_location(loc),
                                                        kind,
                                                        return_type._c_type,
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
                                              type_._c_type)
        return RValue_from_c(c_rvalue)

    def one(self, Type type_):
        """one(self, type_:Type) -> RValue"""
        c_rvalue = c_api.gcc_jit_context_one(self._c_ctxt,
                                             type_._c_type)
        return RValue_from_c(c_rvalue)

    def new_rvalue_from_double(self, Type numeric_type, double value):
        """new_rvalue_from_double(self, numeric_type:Type, value:float) -> RValue"""
        c_rvalue = c_api.gcc_jit_context_new_rvalue_from_double(self._c_ctxt,
                                                                numeric_type._c_type,
                                                                value)
        return RValue_from_c(c_rvalue)

    def new_rvalue_from_int(self, Type type_, int value):
        """new_rvalue_from_int(self, type_:Type, value:int) -> RValue"""
        c_rvalue = c_api.gcc_jit_context_new_rvalue_from_int(self._c_ctxt,
                                                             type_._c_type,
                                                             value)
        return RValue_from_c(c_rvalue)

    # TODO: cannot use a void pointer here
    #def new_rvalue_from_ptr(self, Type pointer_type, void *value):
    #    c_rvalue = c_api.gcc_jit_context_new_rvalue_from_ptr(self._c_ctxt,
    #                                                         pointer_type._c_type,
    #                                                         value)
    #    return RValue_from_c(c_rvalue)

    def null(self, Type pointer_type):
        """null(self, pointer_type:Type) -> RValue"""
        c_rvalue = c_api.gcc_jit_context_null(self._c_ctxt,
                                              pointer_type._c_type)
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
                                                       result_type._c_type,
                                                       rvalue._c_rvalue)
        return RValue_from_c(c_rvalue)

    def new_binary_op(self, op, Type result_type, RValue a, RValue b, Location loc=None):
        """new_binary_op(self, op:BinaryOp, result_type:Type, a:RValue, b:RValue, loc:Location=None) -> RValue"""
        c_rvalue = c_api.gcc_jit_context_new_binary_op(self._c_ctxt,
                                                       get_c_location(loc),
                                                       op,
                                                       result_type._c_type,
                                                       a._c_rvalue,
                                                       b._c_rvalue)
        return RValue_from_c(c_rvalue)

    def new_comparison(self, op, RValue a, RValue b, Location loc=None):
        """new_comparison(self, op:Comparison, a:RValue, b:RValue, loc:Location=None) -> RValue"""
        c_rvalue = c_api.gcc_jit_context_new_comparison(self._c_ctxt,
                                                        get_c_location(loc),
                                                        op,
                                                        a._c_rvalue,
                                                        b._c_rvalue)

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
                                                  rvalue._c_rvalue,
                                                  type_._c_type)
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
            c_args[i] = rvalue._c_rvalue

        c_rvalue = c_api.gcc_jit_context_new_call(self._c_ctxt,
                                                  get_c_location(loc),
                                                  func._c_function,
                                                  num_args,
                                                  c_args)

        free(c_args)
        return RValue_from_c(c_rvalue)


cdef class Result:
    cdef c_api.gcc_jit_result* _c_result
    def __cinit__(self):
        self._c_result = NULL

    cdef _set_c_ptr(self, c_api.gcc_jit_result* c_result):
        self._c_result = c_result

    def get_code(self, funcname):
        cdef void *ptr = c_api.gcc_jit_result_get_code(self._c_result, funcname)
        return <unsigned long>ptr


cdef class Object:
    cdef c_api.gcc_jit_object *_c_object
    pass

cdef Object Object_from_c(c_api.gcc_jit_object *c_object):
    if c_object == NULL:
        raise Exception("Unknown error, got bad object")

    py_object = Object()
    py_object._c_object = c_object
    return py_object


cdef class Type:
    cdef c_api.gcc_jit_type *_c_type
    def __cinit__(self):
        self._c_type = NULL

    cdef _set_c_ptr(self, c_api.gcc_jit_type* c_type):
        self._c_type = c_type

    def get_pointer(self):
        """get_pointer(self) -> Type"""
        return Type_from_c(c_api.gcc_jit_type_get_pointer(self._c_type))

    def get_const(self):
        """get_const(self) -> Type"""
        return Type_from_c(c_api.gcc_jit_type_get_const(self._c_type))

    def get_volatile(self):
        """get_volatile(self) -> Type"""
        return Type_from_c(c_api.gcc_jit_type_get_volatile(self._c_type))

    def as_object(self):
        """as_object(self) -> Object"""
        return Object_from_c(c_api.gcc_jit_type_as_object(self._c_type))


cdef Type_from_c(c_api.gcc_jit_type *c_type):
    t = Type()
    t._set_c_ptr(c_type)
    return t


cdef class Location:
    cdef c_api.gcc_jit_location* _c_location
    pass


cdef c_api.gcc_jit_location* get_c_location(Location py_location):
    """Get a C location pointer given a Python object, handling None."""
    if py_location is None:
        return NULL
    else:
        return py_location._c_location


cdef class Field:
    cdef c_api.gcc_jit_field* _c_field
    pass


cdef class Struct:
    cdef c_api.gcc_jit_struct* _c_struct
    pass


cdef class RValue:
    cdef c_api.gcc_jit_rvalue* _c_rvalue
    pass

cdef RValue RValue_from_c(c_api.gcc_jit_rvalue *c_rvalue):
    if c_rvalue == NULL:
        raise Exception("Unknown error, got bad rvalue")

    py_rvalue = RValue()
    py_rvalue._c_rvalue = c_rvalue
    return py_rvalue


cdef class LValue(RValue):
    cdef c_api.gcc_jit_lvalue* _c_lvalue

    def as_object(self):
        """as_object(self) -> Object"""
        return Object_from_c(c_api.gcc_jit_lvalue_as_object(self._c_lvalue))

    def as_rvalue(self):
        """as_rvalue(self) -> RValue"""
        return RValue_from_c(c_api.gcc_jit_lvalue_as_rvalue(self._c_lvalue))

    def get_address(self, Location loc=None):
        """get_address(self, loc:Location=None) -> RValue"""
        return RValue_from_c(c_api.gcc_jit_lvalue_get_address(self._c_lvalue,
                                                              get_c_location(loc)))


cdef LValue LValue_from_c(c_api.gcc_jit_lvalue *c_lvalue):
    if c_lvalue == NULL:
        raise Exception("Unknown error, got bad lvalue")

    py_lvalue = LValue()
    py_lvalue._c_lvalue = c_lvalue
    py_lvalue._c_rvalue = c_api.gcc_jit_lvalue_as_rvalue(c_lvalue)
    return py_lvalue


cdef class Param(LValue):
    cdef c_api.gcc_jit_param* _c_param

    def as_object(self):
        """as_object(self) -> Object"""
        return Object_from_c(c_api.gcc_jit_param_as_object(self._c_param))

    def as_lvalue(self):
        """as_lvalue(self) -> LValue"""
        return LValue_from_c(c_api.gcc_jit_param_as_lvalue(self._c_param))

    def as_rvalue(self):
        """as_rvalue(self) -> RValue"""
        return RValue_from_c(c_api.gcc_jit_param_as_rvalue(self._c_param))

cdef Param Param_from_c(c_api.gcc_jit_param *c_param):
    if c_param == NULL:
        raise Exception("Unknown error, got bad param")

    p = Param()
    p._c_param = c_param
    p._c_lvalue = c_api.gcc_jit_param_as_lvalue(c_param)
    p._c_rvalue = c_api.gcc_jit_param_as_rvalue(c_param)
    return p


cdef class Function:
    cdef c_api.gcc_jit_function* _c_function

    def new_local(self, Type type_, name, Location loc=None):
        """new_local(self, type_:Type, name:str, loc:Location=None) -> LValue"""
        c_lvalue = c_api.gcc_jit_function_new_local(self._c_function,
                                                    get_c_location(loc),
                                                    type_._c_type,
                                                    name)
        return LValue_from_c(c_lvalue)

    def new_block(self, name):
        """new_block(self, name:str) -> Block"""
        c_block = c_api.gcc_jit_function_new_block(self._c_function,
                                                   name)
        if c_block == NULL:
            raise Exception("foo")
        block = Block()
        block._c_block = c_block
        return block

    def as_object(self):
        """as_object(self) -> Object"""
        c_object = c_api.gcc_jit_function_as_object(self._c_function)
        return Object_from_c(c_object)

    def get_param(self, index):
        """get_param(self, index:int) -> Param"""
        c_param = c_api.gcc_jit_function_get_param (self._c_function, index)
        return Param_from_c(c_param)

    def dump_to_dot(self, char *path):
        """dump_to_dot(self, path:str)"""
        c_api.gcc_jit_function_dump_to_dot (self._c_function,
                                            path)

cdef Function Function_from_c(c_api.gcc_jit_function *c_function):
    if c_function == NULL:
        raise Exception("Unknown error, got bad function")
    f = Function()
    f._c_function = c_function
    return f


cdef class Block:
    cdef c_api.gcc_jit_block* _c_block

    def add_eval(self, RValue rvalue, Location loc=None):
        """add_eval(self, rvalue:RValue, loc:Location=None)"""
        c_api.gcc_jit_block_add_eval(self._c_block,
                                     get_c_location(loc),
                                     rvalue._c_rvalue)

    def add_assignment(self, LValue lvalue, RValue rvalue, Location loc=None):
        """add_assignment(self, lvalue:LValue, rvalue:RValue, loc:Location=None)"""
        c_api.gcc_jit_block_add_assignment(self._c_block,
                                           get_c_location(loc),
                                           lvalue._c_lvalue,
                                           rvalue._c_rvalue)

    def add_assignment_op(self, LValue lvalue, op, RValue rvalue, Location loc=None):
        """add_assignment(self, lvalue:LValue, op:BinaryOp, rvalue:RValue, loc:Location=None)"""
        c_api.gcc_jit_block_add_assignment_op(self._c_block,
                                              get_c_location(loc),
                                              lvalue._c_lvalue,
                                              op,
                                              rvalue._c_rvalue)

    def add_comment(self, text, Location loc=None):
        """add_comment(self, text:str, loc:Location=None)"""
        c_api.gcc_jit_block_add_comment (self._c_block,
                                         get_c_location(loc),
                                         text)

    def end_with_conditional(self, RValue boolval,
                             Block on_true,
                             Block on_false=None,
                             Location loc=None):
        """end_with_conditional(self, on_true:Block, on_false:Block=None, loc:Location=None)"""
        c_api.gcc_jit_block_end_with_conditional(self._c_block,
                                                 get_c_location(loc),
                                                 boolval._c_rvalue,
                                                 on_true._c_block,
                                                 on_false._c_block if on_false else NULL)

    def end_with_jump(self, Block target, Location loc=None):
        """end_with_jump(self, target:Block, loc:Location=None)"""
        c_api.gcc_jit_block_end_with_jump(self._c_block,
                                          get_c_location(loc),
                                          target._c_block)

    def end_with_return(self, RValue rvalue, loc=None):
        """end_with_return(self, rvalue:RValue, loc:Location=None)"""
        c_api.gcc_jit_block_end_with_return(self._c_block,
                                            get_c_location(loc),
                                            rvalue._c_rvalue)

    def end_with_void_return(self, loc=None):
        """end_with_void_return(self, loc:Location=None)"""
        c_api.gcc_jit_block_end_with_void_return(self._c_block,
                                                 get_c_location(loc))

    def as_object(self):
        """as_object(self) -> Object"""
        c_object = c_api.gcc_jit_block_as_object(self._c_block)
        return Object_from_c(c_object)

    def get_function(self):
        """get_function(self) -> Function"""
        c_function = c_api.gcc_jit_block_get_function (self._c_block)
        return Function_from_c(c_function)


cdef class FunctionKind:
    EXPORTED = c_api.GCC_JIT_FUNCTION_EXPORTED
    INTERNAL = c_api.GCC_JIT_FUNCTION_INTERNAL
    IMPORTED = c_api.GCC_JIT_FUNCTION_IMPORTED
    ALWAYS_INLINE = c_api.GCC_JIT_FUNCTION_ALWAYS_INLINE


cdef class UnaryOp:
    MINUS = c_api.GCC_JIT_UNARY_OP_MINUS
    NEGATE = c_api.GCC_JIT_UNARY_OP_BITWISE_NEGATE
    LOGICAL_NEGATE = c_api.GCC_JIT_UNARY_OP_LOGICAL_NEGATE

cdef class BinaryOp:
    PLUS = c_api.GCC_JIT_BINARY_OP_PLUS
    MINUS = c_api.GCC_JIT_BINARY_OP_MINUS
    MULT = c_api.GCC_JIT_BINARY_OP_MULT
    DIVIDE = c_api.GCC_JIT_BINARY_OP_DIVIDE
    MODULO = c_api.GCC_JIT_BINARY_OP_MODULO
    BITWISE_AND = c_api.GCC_JIT_BINARY_OP_BITWISE_AND
    BITWISE_XOR = c_api.GCC_JIT_BINARY_OP_BITWISE_XOR
    BITWISE_OR = c_api.GCC_JIT_BINARY_OP_BITWISE_OR
    LOGICAL_AND = c_api.GCC_JIT_BINARY_OP_LOGICAL_AND
    LOGICAL_OR = c_api.GCC_JIT_BINARY_OP_LOGICAL_OR


cdef class Comparison:
    EQ = c_api.GCC_JIT_COMPARISON_EQ
    NE = c_api.GCC_JIT_COMPARISON_NE
    LT = c_api.GCC_JIT_COMPARISON_LT
    LE = c_api.GCC_JIT_COMPARISON_LE
    GT = c_api.GCC_JIT_COMPARISON_GT
    GE = c_api.GCC_JIT_COMPARISON_GE


cdef class StrOption:
    PROGNAME = c_api.GCC_JIT_STR_OPTION_PROGNAME


cdef class IntOption:
    OPTIMIZATION_LEVEL = c_api.GCC_JIT_INT_OPTION_OPTIMIZATION_LEVEL


cdef class BoolOption:
    DEBUGINFO = c_api.GCC_JIT_BOOL_OPTION_DEBUGINFO
    DUMP_INITIAL_TREE = c_api.GCC_JIT_BOOL_OPTION_DUMP_INITIAL_TREE
    DUMP_INITIAL_GIMPLE = c_api.GCC_JIT_BOOL_OPTION_DUMP_INITIAL_GIMPLE
    DUMP_GENERATED_CODE = c_api.GCC_JIT_BOOL_OPTION_DUMP_GENERATED_CODE
    DUMP_SUMMARY = c_api.GCC_JIT_BOOL_OPTION_DUMP_SUMMARY
    DUMP_EVERYTHING = c_api.GCC_JIT_BOOL_OPTION_DUMP_EVERYTHING
    SELFCHECK_GC = c_api.GCC_JIT_BOOL_OPTION_SELFCHECK_GC
    KEEP_INTERMEDIATES = c_api.GCC_JIT_BOOL_OPTION_KEEP_INTERMEDIATES


cdef class TypeKind:
    VOID = c_api.GCC_JIT_TYPE_VOID
    VOID_PTR = c_api.GCC_JIT_TYPE_VOID_PTR
    CHAR = c_api.GCC_JIT_TYPE_CHAR
    SIGNED_CHAR = c_api.GCC_JIT_TYPE_SIGNED_CHAR
    UNSIGNED_CHAR = c_api.GCC_JIT_TYPE_UNSIGNED_CHAR
    SHORT = c_api.GCC_JIT_TYPE_SHORT
    UNSIGNED_SHORT = c_api.GCC_JIT_TYPE_UNSIGNED_SHORT
    INT = c_api.GCC_JIT_TYPE_INT
    UNSIGNED_INT = c_api.GCC_JIT_TYPE_UNSIGNED_INT
    LONG = c_api.GCC_JIT_TYPE_LONG
    UNSIGNED_LONG = c_api.GCC_JIT_TYPE_UNSIGNED_LONG
    LONG_LONG = c_api.GCC_JIT_TYPE_LONG_LONG
    UNSIGNED_LONG_LONG = c_api.GCC_JIT_TYPE_UNSIGNED_LONG_LONG
    FLOAT = c_api.GCC_JIT_TYPE_FLOAT
    DOUBLE = c_api.GCC_JIT_TYPE_DOUBLE
    LONG_DOUBLE = c_api.GCC_JIT_TYPE_LONG_DOUBLE
    CONST_CHAR_PTR = c_api.GCC_JIT_TYPE_CONST_CHAR_PTR
    SIZE_T = c_api.GCC_JIT_TYPE_SIZE_T
    FILE_PTR = c_api.GCC_JIT_TYPE_FILE_PTR
