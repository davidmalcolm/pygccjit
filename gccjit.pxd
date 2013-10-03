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

cdef extern from "libgccjit.h":
    ctypedef struct gcc_jit_context:
        pass
    ctypedef struct gcc_jit_result:
        pass
    ctypedef struct gcc_jit_location:
        pass
    ctypedef struct gcc_jit_type:
        pass
    ctypedef struct gcc_jit_function:
        pass
    ctypedef struct gcc_jit_label:
        pass
    ctypedef struct gcc_jit_rvalue:
        pass
    ctypedef struct gcc_jit_lvalue:
        pass
    ctypedef struct gcc_jit_param:
        pass
    ctypedef struct gcc_jit_local:
        pass
    ctypedef struct gcc_jit_loop:
        pass

    ctypedef void (*gcc_jit_code_callback) (gcc_jit_context *ctxt, void *user_data)

    gcc_jit_context * gcc_jit_context_acquire ()
    void gcc_jit_context_release (gcc_jit_context *ctxt)

    void gcc_jit_context_set_code_factory (gcc_jit_context *ctxt,
                                           gcc_jit_code_callback cb, void *user_data)

    gcc_jit_type *gcc_jit_context_get_void_type (gcc_jit_context *ctxt)
    gcc_jit_type *gcc_jit_context_get_char_type (gcc_jit_context *ctxt)
    gcc_jit_type *gcc_jit_context_get_int_type (gcc_jit_context *ctxt)
    gcc_jit_type *gcc_jit_context_get_float_type (gcc_jit_context *ctxt)
    gcc_jit_type *gcc_jit_context_get_double_type (gcc_jit_context *ctxt)

    gcc_jit_type *gcc_jit_type_get_pointer (gcc_jit_type *type)
    gcc_jit_type *gcc_jit_type_get_const (gcc_jit_type *type)

    gcc_jit_param *gcc_jit_context_new_param (gcc_jit_context *ctxt,
                                              gcc_jit_location *loc,
                                              gcc_jit_type *type,
                                              char *name)
    gcc_jit_lvalue *gcc_jit_param_as_lvalue (gcc_jit_param *param)
    gcc_jit_rvalue *gcc_jit_param_as_rvalue (gcc_jit_param *param)

    cdef enum gcc_jit_function_kind:
        GCC_JIT_FUNCTION_EXPORTED,
        GCC_JIT_FUNCTION_INTERNAL,
        GCC_JIT_FUNCTION_IMPORTED

    gcc_jit_function *gcc_jit_context_new_function (gcc_jit_context *ctxt,
                                                    gcc_jit_location *loc,
                                                    gcc_jit_function_kind kind,
                                                    gcc_jit_type *return_type,
                                                    char *name,
                                                    int num_params,
                                                    gcc_jit_param **params,
                                                    int is_variadic)

    gcc_jit_label *gcc_jit_function_new_forward_label (gcc_jit_function *func,
                                                       char *name)

    gcc_jit_local *gcc_jit_context_new_local (gcc_jit_context *ctxt,
                                              gcc_jit_location *loc,
                                              gcc_jit_type *type,
                                              char *name)

    gcc_jit_lvalue *gcc_jit_local_as_lvalue (gcc_jit_local *local)

    gcc_jit_rvalue *gcc_jit_local_as_rvalue (gcc_jit_local *local)

    gcc_jit_rvalue *gcc_jit_lvalue_as_rvalue (gcc_jit_lvalue *lvalue)

    gcc_jit_rvalue *gcc_jit_context_new_rvalue_from_int (gcc_jit_context *ctxt,
                                                         gcc_jit_type *type,
                                                         int value)

    gcc_jit_rvalue *gcc_jit_context_zero (gcc_jit_context *ctxt,
                      gcc_jit_type *type)

    gcc_jit_rvalue *gcc_jit_context_one (gcc_jit_context *ctxt,
                     gcc_jit_type *type)

    gcc_jit_rvalue *gcc_jit_context_new_string_literal (gcc_jit_context *ctxt,
                                                        char *value)


    cdef enum gcc_jit_binary_op:
        GCC_JIT_BINARY_OP_PLUS,
        GCC_JIT_BINARY_OP_MINUS,
        GCC_JIT_BINARY_OP_MULT

    gcc_jit_rvalue *gcc_jit_context_new_binary_op (gcc_jit_context *ctxt,
                                                   gcc_jit_location *loc,
                                                   gcc_jit_binary_op op,
                                                   gcc_jit_type *result_type,
                                                   gcc_jit_rvalue *a,
                                                   gcc_jit_rvalue *b)

    cdef enum gcc_jit_comparison:
        GCC_JIT_COMPARISON_LT,
        GCC_JIT_COMPARISON_GE

    gcc_jit_rvalue *gcc_jit_context_new_comparison (gcc_jit_context *ctxt,
                                                    gcc_jit_location *loc,
                                                    gcc_jit_comparison op,
                                                    gcc_jit_rvalue *a,
                                                    gcc_jit_rvalue *b)

    gcc_jit_rvalue *gcc_jit_context_new_call (gcc_jit_context *ctxt,
                                              gcc_jit_location *loc,
                                              gcc_jit_function *func,
                                              int numargs ,
                                              gcc_jit_rvalue **args)

    gcc_jit_rvalue *gcc_jit_context_new_array_lookup (gcc_jit_context *ctxt,
                                  gcc_jit_location *loc,
                                  gcc_jit_rvalue *ptr,
                                  gcc_jit_rvalue *index)

    void gcc_jit_function_add_eval (gcc_jit_function *func,
                                    gcc_jit_location *loc,
                                    gcc_jit_rvalue *rvalue)

    void gcc_jit_function_add_assignment (gcc_jit_function *func,
                                          gcc_jit_location *loc,
                                          gcc_jit_lvalue *lvalue,
                                          gcc_jit_rvalue *rvalue)

    void gcc_jit_function_add_assignment_op (gcc_jit_function *func,
                                    gcc_jit_location *loc,
                                    gcc_jit_lvalue *lvalue,
                                    gcc_jit_binary_op op,
                                    gcc_jit_rvalue *rvalue)

    void gcc_jit_function_add_conditional (gcc_jit_function *func,
                                           gcc_jit_location *loc,
                                           gcc_jit_rvalue *boolval,
                                           gcc_jit_label *on_true,
                                           gcc_jit_label *on_false)

    gcc_jit_label *gcc_jit_function_add_label (gcc_jit_function *func,
                                               gcc_jit_location *loc,
                                               char *name)

    void gcc_jit_function_place_forward_label (gcc_jit_function *func,
                                               gcc_jit_label *lab)

    void gcc_jit_function_add_jump (gcc_jit_function *func,
                                    gcc_jit_location *loc,
                                    gcc_jit_label *target)

    void gcc_jit_function_add_return (gcc_jit_function *func,
                                      gcc_jit_location *loc,
                                      gcc_jit_rvalue *rvalue)

    gcc_jit_loop *gcc_jit_function_new_loop (gcc_jit_function *func,
                                             gcc_jit_location *loc,
                                             gcc_jit_rvalue *boolval)

    void gcc_jit_loop_end (gcc_jit_loop *loop,
                           gcc_jit_location *loc)

    # Option-management

    cdef enum gcc_jit_str_option:
        GCC_JIT_STR_OPTION_PROGNAME
        GCC_JIT_NUM_STR_OPTIONS

    cdef enum gcc_jit_int_option:
        GCC_JIT_INT_OPTION_OPTIMIZATION_LEVEL
        GCC_JIT_NUM_INT_OPTIONS

    cdef enum gcc_jit_bool_option:
        GCC_JIT_BOOL_OPTION_DEBUGINFO
        GCC_JIT_BOOL_OPTION_DUMP_INITIAL_TREE
        GCC_JIT_BOOL_OPTION_DUMP_INITIAL_GIMPLE
        GCC_JIT_NUM_BOOL_OPTIONS

    void gcc_jit_context_set_str_option (gcc_jit_context *ctxt,
                                         gcc_jit_str_option opt,
                                         char *value)

    void gcc_jit_context_set_int_option (gcc_jit_context *ctxt,
                                         gcc_jit_int_option opt,
                                         int value)

    void gcc_jit_context_set_bool_option (gcc_jit_context *ctxt,
                                          gcc_jit_bool_option opt,
                                          int value)

    gcc_jit_result *gcc_jit_context_compile (gcc_jit_context *ctxt)
    void *gcc_jit_result_get_code (gcc_jit_result *result, char *funcname)

    void gcc_jit_result_release (gcc_jit_result *result)
