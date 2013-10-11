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

    def new_param(self, Type type_, name, loc=None):
        c_result = c_api.gcc_jit_context_new_param(self._c_ctxt,
                                                   NULL,
                                                   type_._c_type,
                                                   name)
        p = Param()
        p._c_param = c_result
        p._c_lvalue = c_api.gcc_jit_param_as_lvalue(c_result)
        p._c_rvalue = c_api.gcc_jit_param_as_rvalue(c_result)
        return p

    def new_function(self, kind, Type return_type, name, params,
                     loc=None,
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

    def new_local(self, Type type_, name, loc=None):
        c_local = c_api.gcc_jit_context_new_local (self._c_ctxt,
                                                   NULL,
                                                   type_._c_type,
                                                   name)
        if c_local == NULL:
            raise Exception("foo")
        result = Local()
        result._c_local = c_local
        result._c_lvalue = c_api.gcc_jit_local_as_lvalue(c_local)
        result._c_rvalue = c_api.gcc_jit_local_as_rvalue(c_local)
        return result

    def zero(self, Type type_):
        c_rvalue = c_api.gcc_jit_context_zero(self._c_ctxt,
                                              type_._c_type)
        if c_rvalue == NULL:
            raise Exception("foo")
        result = RValue()
        result._c_rvalue = c_rvalue
        return result

    def one(self, Type type_):
        c_rvalue = c_api.gcc_jit_context_one(self._c_ctxt,
                                             type_._c_type)
        if c_rvalue == NULL:
            raise Exception("foo")
        result = RValue()
        result._c_rvalue = c_rvalue
        return result

    def new_binary_op (self, op, Type result_type, RValue a, RValue b,
                       loc=None):
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

    def new_comparison(self, op, RValue a, RValue b, loc=None):
        c_rvalue = c_api.gcc_jit_context_new_comparison (self._c_ctxt,
                                                        NULL,
                                                        op,
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

cdef class Label:
    cdef c_api.gcc_jit_label* _c_label
    pass

cdef class RValue:
    cdef c_api.gcc_jit_rvalue* _c_rvalue
    pass

cdef class LValue(RValue):
    cdef c_api.gcc_jit_lvalue* _c_lvalue
    pass

cdef class Param(LValue):
    cdef c_api.gcc_jit_param* _c_param
    pass

cdef class Local(LValue):
    cdef c_api.gcc_jit_local* _c_local
    pass

cdef class Function:
    cdef c_api.gcc_jit_function* _c_function

    def new_forward_label(self, name):
        c_label = c_api.gcc_jit_function_new_forward_label(self._c_function,
                                                           name)
        if c_label == NULL:
            raise Exception("foo")
        label = Label()
        label._c_label = c_label
        return label

    def add_assignment(self, LValue lvalue, RValue rvalue, loc=None):
        c_api.gcc_jit_function_add_assignment(self._c_function,
                                              NULL,
                                              lvalue._c_lvalue,
                                              rvalue._c_rvalue)

    def add_assignment_op(self, LValue lvalue, op, RValue rvalue, loc=None):
        c_api.gcc_jit_function_add_assignment_op(self._c_function,
                                                 NULL,
                                                 lvalue._c_lvalue,
                                                 op,
                                                 rvalue._c_rvalue)

    def add_conditional(self, RValue boolval,
                        Label on_true, Label on_false,
                        loc=None):
        c_api.gcc_jit_function_add_conditional(self._c_function,
                                               NULL,
                                               boolval._c_rvalue,
                                               on_true._c_label,
                                               on_false._c_label)

    def add_label(self, name, loc=None):
        c_label = c_api.gcc_jit_function_add_label(self._c_function,
                                                   NULL,
                                                   name)
        if c_label == NULL:
            raise Exception("foo")
        label = Label()
        label._c_label = c_label
        return label

    def place_forward_label(self, Label label):
        c_api.gcc_jit_function_place_forward_label (self._c_function,
                                                    label._c_label)

    def add_jump(self, Label target, loc=None):
        c_api.gcc_jit_function_add_jump(self._c_function,
                                        NULL,
                                        target._c_label)

    def add_return(self, RValue rvalue, loc=None):
        c_api.gcc_jit_function_add_return (self._c_function,
                                           NULL,
                                           rvalue._c_rvalue)

FUNCTION_EXPORTED = c_api.GCC_JIT_FUNCTION_EXPORTED
FUNCTION_INTERNAL = c_api.GCC_JIT_FUNCTION_INTERNAL
FUNCTION_IMPORTED = c_api.GCC_JIT_FUNCTION_IMPORTED

BINARY_OP_PLUS = c_api.GCC_JIT_BINARY_OP_PLUS
BINARY_OP_MINUS = c_api.GCC_JIT_BINARY_OP_MINUS
BINARY_OP_MULT = c_api.GCC_JIT_BINARY_OP_MULT

COMPARISON_LT = c_api.GCC_JIT_COMPARISON_LT
COMPARISON_GE = c_api.GCC_JIT_COMPARISON_GE

STR_OPTION_PROGNAME = c_api.GCC_JIT_STR_OPTION_PROGNAME

INT_OPTION_OPTIMIZATION_LEVEL = c_api.GCC_JIT_INT_OPTION_OPTIMIZATION_LEVEL

BOOL_OPTION_DEBUGINFO = c_api.GCC_JIT_BOOL_OPTION_DEBUGINFO
BOOL_OPTION_DUMP_INITIAL_TREE = c_api.GCC_JIT_BOOL_OPTION_DUMP_INITIAL_TREE
BOOL_OPTION_DUMP_INITIAL_GIMPLE = c_api.GCC_JIT_BOOL_OPTION_DUMP_INITIAL_GIMPLE
BOOL_OPTION_DUMP_SUMMARY = c_api.GCC_JIT_BOOL_OPTION_DUMP_SUMMARY
BOOL_OPTION_DUMP_EVERYTHING = c_api.GCC_JIT_BOOL_OPTION_DUMP_EVERYTHING
BOOL_OPTION_KEEP_INTERMEDIATES = c_api.GCC_JIT_BOOL_OPTION_KEEP_INTERMEDIATES
