#   Copyright 2013 David Malcolm <dmalcolm@redhat.com>
#   Copyright 2013 Red Hat, Inc.
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

cdef int _c_callback(c_api.gcc_jit_context* c_ctxt, object user_data) except -1:
    ctxt = <Context>user_data;
    try:
        ctxt.code_factory(ctxt)
    except Exception, exc:
        ctxt.stored_exception = exc
        return -1
    return 0
    #        c_api.gcc_jit_context_add_error(c_ctxt, "Python exception")
    #    raise

cdef class Context:
    cdef c_api.gcc_jit_context* _c_ctxt
    cdef object code_factory
    cdef object stored_exception

    def __cinit__(self, code_factory):
        self._c_ctxt = c_api.gcc_jit_context_acquire()
        self.code_factory = code_factory
        c_api.gcc_jit_context_set_code_factory(
            self._c_ctxt,
            <c_api.gcc_jit_code_callback>_c_callback,
            <void *>self)

    def __dealloc__(self):
        c_api.gcc_jit_context_release(self._c_ctxt)

    def set_bool_option(self, opt, val):
        c_api.gcc_jit_context_set_bool_option(self._c_ctxt, opt, val)
    def set_int_option(self, opt, val):
        c_api.gcc_jit_context_set_int_option(self._c_ctxt, opt, val)

    def get_void_type(self):
        return make_type(c_api.gcc_jit_context_get_void_type(self._c_ctxt))
    def get_char_type(self):
        return make_type(c_api.gcc_jit_context_get_char_type(self._c_ctxt))
    def get_int_type(self):
        return make_type(c_api.gcc_jit_context_get_int_type(self._c_ctxt))
    def get_float_type(self):
        return make_type(c_api.gcc_jit_context_get_float_type(self._c_ctxt))
    def get_double_type(self):
        return make_type(c_api.gcc_jit_context_get_double_type(self._c_ctxt))

    def compile(self):
        cdef c_api.gcc_jit_result *c_result
        c_result = c_api.gcc_jit_context_compile(self._c_ctxt)
        if c_result == NULL:
            raise self.stored_exception
        r = Result()
        r._set_c_ptr(c_result)
        return r

    def new_param(self, loc, Type type_, name):
        c_result = c_api.gcc_jit_context_new_param(self._c_ctxt,
                                                   NULL,
                                                   type_._c_type,
                                                   name)
        p = Param()
        p._c_param = c_result
        p._c_lvalue = c_api.gcc_jit_param_as_lvalue(c_result)
        p._c_rvalue = c_api.gcc_jit_param_as_rvalue(c_result)
        return p

    def new_function(self, loc, kind, Type return_type, name, params,
                     is_variadic=False):
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
        c_function = c_api.gcc_jit_context_new_function (self._c_ctxt,
                                                         NULL,
                                                         kind,
                                                         return_type._c_type,
                                                         name,
                                                         len(params),
                                                         c_params,
                                                         is_variadic)
        free(c_params)

        f = Function()
        f._c_function = c_function
        return f

    def new_binary_op (self, loc, op, Type result_type, RValue a, RValue b):
        c_rvalue = c_api.gcc_jit_context_new_binary_op (self._c_ctxt,
                                                        NULL,
                                                        op,
                                                        result_type._c_type,
                                                        a._c_rvalue,
                                                        b._c_rvalue)
        if c_rvalue == NULL:
            raise Exception("foo")
        result = RValue()
        result._c_rvalue = c_rvalue
        return result

cdef class Result:
    cdef c_api.gcc_jit_result* _c_result
    def __cinit__(self):
        self._c_result = NULL

    cdef _set_c_ptr(self, c_api.gcc_jit_result* c_result):
        self._c_result = c_result

    def get_code(self, funcname):
        cdef void *ptr = c_api.gcc_jit_result_get_code (self._c_result, funcname)
        from ctypes import CFUNCTYPE, c_int
        type_ = CFUNCTYPE(c_int, c_int) # FIXME
        callable_ = type_(<long>ptr)
        return callable_

cdef class Type:
    cdef c_api.gcc_jit_type *_c_type
    def __cinit__(self):
        self._c_type = NULL

    cdef _set_c_ptr(self, c_api.gcc_jit_type* c_type):
        self._c_type = c_type

    def get_pointer(self):
        return make_type(c_api.gcc_jit_type_get_pointer(self._c_type))
    def get_const(self):
        return make_type(c_api.gcc_jit_type_get_const(self._c_type))

cdef make_type(c_api.gcc_jit_type *c_type):
    t = Type()
    t._set_c_ptr(c_type)
    return t

cdef class RValue:
    cdef c_api.gcc_jit_rvalue* _c_rvalue
    pass

cdef class LValue(RValue):
    cdef c_api.gcc_jit_lvalue* _c_lvalue
    pass

cdef class Param(LValue):
    cdef c_api.gcc_jit_param* _c_param
    pass

cdef class Function:
    cdef c_api.gcc_jit_function* _c_function

    def add_return(self, loc, RValue rvalue):
        c_api.gcc_jit_function_add_return (self._c_function,
                                           NULL,
                                           rvalue._c_rvalue)

FUNCTION_EXPORTED = c_api.GCC_JIT_FUNCTION_EXPORTED
FUNCTION_INTERNAL = c_api.GCC_JIT_FUNCTION_INTERNAL
FUNCTION_IMPORTED = c_api.GCC_JIT_FUNCTION_IMPORTED

BINARY_OP_PLUS = c_api.GCC_JIT_BINARY_OP_PLUS
BINARY_OP_MINUS = c_api.GCC_JIT_BINARY_OP_MINUS
BINARY_OP_MULT = c_api.GCC_JIT_BINARY_OP_MULT

STR_OPTION_PROGNAME = c_api.GCC_JIT_STR_OPTION_PROGNAME

INT_OPTION_OPTIMIZATION_LEVEL = c_api.GCC_JIT_INT_OPTION_OPTIMIZATION_LEVEL

BOOL_OPTION_DEBUGINFO = c_api.GCC_JIT_BOOL_OPTION_DEBUGINFO
BOOL_OPTION_DUMP_INITIAL_TREE = c_api.GCC_JIT_BOOL_OPTION_DUMP_INITIAL_TREE
BOOL_OPTION_DUMP_INITIAL_GIMPLE = c_api.GCC_JIT_BOOL_OPTION_DUMP_INITIAL_GIMPLE
