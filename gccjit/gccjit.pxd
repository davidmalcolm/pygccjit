#   Copyright 2013-2015 David Malcolm <dmalcolm@redhat.com>
#   Copyright 2013-2015 Red Hat, Inc.
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

from libc.stdio cimport *

cdef extern from "libgccjit.h":

    #
    # Data structures.
    #
    ctypedef struct gcc_jit_object:
        pass
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
    ctypedef struct gcc_jit_block:
        pass
    ctypedef struct gcc_jit_rvalue:
        pass
    ctypedef struct gcc_jit_lvalue:
        pass
    ctypedef struct gcc_jit_param:
        pass
    ctypedef struct gcc_jit_field:
        pass
    ctypedef struct gcc_jit_struct:
        pass

    cdef enum gcc_jit_types:
        GCC_JIT_TYPE_VOID,
        GCC_JIT_TYPE_VOID_PTR,
        GCC_JIT_TYPE_BOOL,
        GCC_JIT_TYPE_CHAR,
        GCC_JIT_TYPE_SIGNED_CHAR,
        GCC_JIT_TYPE_UNSIGNED_CHAR,
        GCC_JIT_TYPE_SHORT,
        GCC_JIT_TYPE_UNSIGNED_SHORT,
        GCC_JIT_TYPE_INT,
        GCC_JIT_TYPE_UNSIGNED_INT,
        GCC_JIT_TYPE_LONG,
        GCC_JIT_TYPE_UNSIGNED_LONG,
        GCC_JIT_TYPE_LONG_LONG,
        GCC_JIT_TYPE_UNSIGNED_LONG_LONG,
        GCC_JIT_TYPE_FLOAT,
        GCC_JIT_TYPE_DOUBLE,
        GCC_JIT_TYPE_LONG_DOUBLE,
        GCC_JIT_TYPE_CONST_CHAR_PTR,
        GCC_JIT_TYPE_SIZE_T,
        GCC_JIT_TYPE_FILE_PTR

    #
    # Option-management
    #

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
        GCC_JIT_BOOL_OPTION_DUMP_GENERATED_CODE
        GCC_JIT_BOOL_OPTION_DUMP_SUMMARY
        GCC_JIT_BOOL_OPTION_DUMP_EVERYTHING
        GCC_JIT_BOOL_OPTION_SELFCHECK_GC
        GCC_JIT_BOOL_OPTION_KEEP_INTERMEDIATES
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

    #
    # Context management
    #

    gcc_jit_context *gcc_jit_context_acquire ()
    void gcc_jit_context_release (gcc_jit_context *ctxt)

    gcc_jit_result *gcc_jit_context_compile (gcc_jit_context *ctxt)

    cdef enum gcc_jit_output_kind:
        GCC_JIT_OUTPUT_KIND_ASSEMBLER
        GCC_JIT_OUTPUT_KIND_OBJECT_FILE
        GCC_JIT_OUTPUT_KIND_DYNAMIC_LIBRARY
        GCC_JIT_OUTPUT_KIND_EXECUTABLE

    void gcc_jit_context_compile_to_file (gcc_jit_context *ctxt,
                                          gcc_jit_output_kind output_kind,
                                          char *output_path)

    void gcc_jit_context_dump_to_file (gcc_jit_context *ctxt,
                                       char *path,
                                       int update_locations)

    char *gcc_jit_context_get_first_error (gcc_jit_context *ctxt)
    char *gcc_jit_context_get_last_error (gcc_jit_context *ctxt)


    void *gcc_jit_result_get_code (gcc_jit_result *result, char *funcname)

    void gcc_jit_result_release (gcc_jit_result *result)

    gcc_jit_context *gcc_jit_object_get_context (gcc_jit_object *obj)

    char *gcc_jit_object_get_debug_string (gcc_jit_object *obj)

    gcc_jit_location *gcc_jit_context_new_location (gcc_jit_context *ctxt,
                                                    char *filename,
                                                    int line,
                                                    int column)

    gcc_jit_object *gcc_jit_location_as_object (gcc_jit_location *loc)


    #
    # Types
    #

    gcc_jit_object *gcc_jit_type_as_object (gcc_jit_type *type)


    gcc_jit_type *gcc_jit_context_get_type (gcc_jit_context *ctxt,
                                            gcc_jit_types type_enum)

    gcc_jit_type *gcc_jit_context_get_int_type (gcc_jit_context *ctxt,
                                                int num_bytes, int is_signed)

    gcc_jit_type *gcc_jit_type_get_pointer (gcc_jit_type *type)
    gcc_jit_type *gcc_jit_type_get_const (gcc_jit_type *type)
    gcc_jit_type *gcc_jit_type_get_volatile (gcc_jit_type *type)

    gcc_jit_type *gcc_jit_context_new_array_type (gcc_jit_context *ctxt,
                                                  gcc_jit_location *loc,
                                                  gcc_jit_type *element_type,
                                                  int num_elements)

    gcc_jit_field *gcc_jit_context_new_field (gcc_jit_context *ctxt,
                                              gcc_jit_location *loc,
                                              gcc_jit_type *type,
                                              char *name)

    gcc_jit_object *gcc_jit_field_as_object (gcc_jit_field *field)

    gcc_jit_struct *gcc_jit_context_new_struct_type (gcc_jit_context *ctxt,
                                                     gcc_jit_location *loc,
                                                     const char *name,
                                                     int num_fields,
                                                     gcc_jit_field **fields)

    gcc_jit_struct *gcc_jit_context_new_opaque_struct (gcc_jit_context *ctxt,
                                                       gcc_jit_location *loc,
                                                       const char *name)

    gcc_jit_type *gcc_jit_struct_as_type (gcc_jit_struct *struct_type)

    void gcc_jit_struct_set_fields (gcc_jit_struct *struct_type,
                                    gcc_jit_location *loc,
                                    int num_fields,
                                    gcc_jit_field **fields)


    gcc_jit_type *gcc_jit_context_new_union_type (gcc_jit_context *ctxt,
                                                  gcc_jit_location *loc,
                                                  const char *name,
                                                  int num_fields,
                                                  gcc_jit_field **fields)

    gcc_jit_type *gcc_jit_context_new_function_ptr_type (gcc_jit_context *ctxt,
                                                         gcc_jit_location *loc,
                                                         gcc_jit_type *return_type,
                                                         int num_params,
                                                         gcc_jit_type **param_types,
                                                         int is_variadic)
    #
    # Constructing functions.
    #

    gcc_jit_param *gcc_jit_context_new_param (gcc_jit_context *ctxt,
                                              gcc_jit_location *loc,
                                              gcc_jit_type *type,
                                              char *name)
    gcc_jit_object *gcc_jit_param_as_object (gcc_jit_param *param)
    gcc_jit_lvalue *gcc_jit_param_as_lvalue (gcc_jit_param *param)
    gcc_jit_rvalue *gcc_jit_param_as_rvalue (gcc_jit_param *param)

    cdef enum gcc_jit_function_kind:
        GCC_JIT_FUNCTION_EXPORTED,
        GCC_JIT_FUNCTION_INTERNAL,
        GCC_JIT_FUNCTION_IMPORTED,
        GCC_JIT_FUNCTION_ALWAYS_INLINE

    gcc_jit_function *gcc_jit_context_new_function (gcc_jit_context *ctxt,
                                                    gcc_jit_location *loc,
                                                    gcc_jit_function_kind kind,
                                                    gcc_jit_type *return_type,
                                                    char *name,
                                                    int num_params,
                                                    gcc_jit_param **params,
                                                    int is_variadic)

    gcc_jit_function *gcc_jit_context_get_builtin_function (gcc_jit_context *ctxt,
                                                            char *name)

    gcc_jit_object *gcc_jit_function_as_object (gcc_jit_function *func)

    gcc_jit_param *gcc_jit_function_get_param (gcc_jit_function *func, int index)

    void gcc_jit_function_dump_to_dot (gcc_jit_function *func,
                                       char *path)

    gcc_jit_block *gcc_jit_function_new_block (gcc_jit_function *func,
                                               char *name)

    gcc_jit_object *gcc_jit_block_as_object (gcc_jit_block *block)

    gcc_jit_function *gcc_jit_block_get_function (gcc_jit_block *block)


    #
    # lvalues, rvalues and expressions.
    #
    cdef enum gcc_jit_global_kind:
        GCC_JIT_GLOBAL_EXPORTED,
        GCC_JIT_GLOBAL_INTERNAL,
        GCC_JIT_GLOBAL_IMPORTED

    gcc_jit_lvalue *gcc_jit_context_new_global (gcc_jit_context *ctxt,
                                                gcc_jit_location *loc,
                                                gcc_jit_global_kind kind,
                                                gcc_jit_type *type,
                                                char *name)

    gcc_jit_object *gcc_jit_lvalue_as_object (gcc_jit_lvalue *lvalue)

    gcc_jit_rvalue *gcc_jit_lvalue_as_rvalue (gcc_jit_lvalue *lvalue)

    gcc_jit_object *gcc_jit_rvalue_as_object (gcc_jit_rvalue *rvalue)

    gcc_jit_type *gcc_jit_rvalue_get_type (gcc_jit_rvalue *rvalue)

    gcc_jit_rvalue *gcc_jit_context_new_rvalue_from_int (gcc_jit_context *ctxt,
                                                         gcc_jit_type *type,
                                                         int value)

    gcc_jit_rvalue *gcc_jit_context_zero (gcc_jit_context *ctxt,
                      gcc_jit_type *type)

    gcc_jit_rvalue *gcc_jit_context_one (gcc_jit_context *ctxt,
                     gcc_jit_type *type)

    gcc_jit_rvalue *gcc_jit_context_new_rvalue_from_double (gcc_jit_context *ctxt,
                        gcc_jit_type *numeric_type,
                        double value)

    gcc_jit_rvalue *gcc_jit_context_new_rvalue_from_ptr (gcc_jit_context *ctxt,
                         gcc_jit_type *pointer_type,
                         void *value)

    gcc_jit_rvalue *gcc_jit_context_null (gcc_jit_context *ctxt,
                  gcc_jit_type *pointer_type)

    gcc_jit_rvalue *gcc_jit_context_new_string_literal (gcc_jit_context *ctxt,
                                                        char *value)

    cdef enum gcc_jit_unary_op:
        GCC_JIT_UNARY_OP_MINUS,
        GCC_JIT_UNARY_OP_BITWISE_NEGATE,
        GCC_JIT_UNARY_OP_LOGICAL_NEGATE,
        GCC_JIT_UNARY_OP_ABS

    gcc_jit_rvalue *gcc_jit_context_new_unary_op (gcc_jit_context *ctxt,
                      gcc_jit_location *loc,
                      gcc_jit_unary_op op,
                      gcc_jit_type *result_type,
                      gcc_jit_rvalue *rvalue)


    cdef enum gcc_jit_binary_op:
        GCC_JIT_BINARY_OP_PLUS,
        GCC_JIT_BINARY_OP_MINUS,
        GCC_JIT_BINARY_OP_MULT
        GCC_JIT_BINARY_OP_DIVIDE,
        GCC_JIT_BINARY_OP_MODULO,
        GCC_JIT_BINARY_OP_BITWISE_AND,
        GCC_JIT_BINARY_OP_BITWISE_XOR,
        GCC_JIT_BINARY_OP_BITWISE_OR,
        GCC_JIT_BINARY_OP_LOGICAL_AND,
        GCC_JIT_BINARY_OP_LOGICAL_OR

    gcc_jit_rvalue *gcc_jit_context_new_binary_op (gcc_jit_context *ctxt,
                                                   gcc_jit_location *loc,
                                                   gcc_jit_binary_op op,
                                                   gcc_jit_type *result_type,
                                                   gcc_jit_rvalue *a,
                                                   gcc_jit_rvalue *b)

    cdef enum gcc_jit_comparison:
        GCC_JIT_COMPARISON_EQ,
        GCC_JIT_COMPARISON_NE,
        GCC_JIT_COMPARISON_LT,
        GCC_JIT_COMPARISON_LE,
        GCC_JIT_COMPARISON_GT,
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

    gcc_jit_rvalue *gcc_jit_context_new_call_through_ptr (gcc_jit_context *ctxt,
                                                          gcc_jit_location *loc,
                                                          gcc_jit_rvalue *fn_ptr,
                                                          int numargs,
                                                          gcc_jit_rvalue **args)

    gcc_jit_rvalue *gcc_jit_context_new_cast (gcc_jit_context *ctxt,
                  gcc_jit_location *loc,
                  gcc_jit_rvalue *rvalue,
                  gcc_jit_type *type)


    gcc_jit_lvalue *gcc_jit_context_new_array_access (gcc_jit_context *ctxt,
                                  gcc_jit_location *loc,
                                  gcc_jit_rvalue *ptr,
                                  gcc_jit_rvalue *index)

    gcc_jit_lvalue *gcc_jit_lvalue_access_field (gcc_jit_lvalue *struct_,
                     gcc_jit_location *loc,
                     gcc_jit_field *field)

    gcc_jit_rvalue *gcc_jit_rvalue_access_field (gcc_jit_rvalue *struct_,
                     gcc_jit_location *loc,
                     gcc_jit_field *field)

    gcc_jit_lvalue *gcc_jit_rvalue_dereference_field (gcc_jit_rvalue *ptr,
                      gcc_jit_location *loc,
                      gcc_jit_field *field)

    gcc_jit_lvalue *gcc_jit_rvalue_dereference (gcc_jit_rvalue *rvalue,
                    gcc_jit_location *loc)

    gcc_jit_rvalue *gcc_jit_lvalue_get_address (gcc_jit_lvalue *lvalue,
                    gcc_jit_location *loc)

    gcc_jit_lvalue *gcc_jit_function_new_local (gcc_jit_function *func,
                                                gcc_jit_location *loc,
                                                gcc_jit_type *type,
                                                char *name)


    #
    # Statement-creation.
    #

    void gcc_jit_block_add_eval (gcc_jit_block *block,
                                 gcc_jit_location *loc,
                                 gcc_jit_rvalue *rvalue)

    void gcc_jit_block_add_assignment (gcc_jit_block *block,
                                       gcc_jit_location *loc,
                                       gcc_jit_lvalue *lvalue,
                                       gcc_jit_rvalue *rvalue)

    void gcc_jit_block_add_assignment_op (gcc_jit_block *block,
                                          gcc_jit_location *loc,
                                          gcc_jit_lvalue *lvalue,
                                          gcc_jit_binary_op op,
                                          gcc_jit_rvalue *rvalue)

    void gcc_jit_block_add_comment (gcc_jit_block *block,
                                    gcc_jit_location *loc,
                                    char *text)

    void gcc_jit_block_end_with_conditional (gcc_jit_block *block,
                                             gcc_jit_location *loc,
                                             gcc_jit_rvalue *boolval,
                                             gcc_jit_block *on_true,
                                             gcc_jit_block *on_false)

    void gcc_jit_block_end_with_jump (gcc_jit_block *block,
                                      gcc_jit_location *loc,
                                      gcc_jit_block *target)

    void gcc_jit_block_end_with_return (gcc_jit_block *block,
                                        gcc_jit_location *loc,
                                        gcc_jit_rvalue *rvalue)

    void gcc_jit_block_end_with_void_return (gcc_jit_block *block,
                                             gcc_jit_location *loc)

    #
    # Nested contexts.
    #

    gcc_jit_context *gcc_jit_context_new_child_context (gcc_jit_context *parent_ctxt)

    void gcc_jit_context_dump_reproducer_to_file (gcc_jit_context *ctxt,
                                                  const char *path)

    void gcc_jit_context_set_logfile (gcc_jit_context *ctxt,
                                      FILE *logfile,
                                      int flags,
                                      int verbosity)
