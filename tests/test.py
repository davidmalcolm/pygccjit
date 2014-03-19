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

import unittest
import ctypes

import gccjit

int_int_func_type = ctypes.CFUNCTYPE(ctypes.c_int, ctypes.c_int)


class JitTests(unittest.TestCase):
    def test_square(self):
        def cb(ctxt):
            """
            Create this function:
              int square(int i)
              {
                 return i * i;
              }
            """
            param_i = ctxt.new_param(ctxt.get_type(gccjit.TypeKind.INT),
                                     b'i')
            fn = ctxt.new_function(gccjit.FunctionKind.EXPORTED,
                                   ctxt.get_type(gccjit.TypeKind.INT),
                                   b"square",
                                   [param_i])

            block = fn.new_block(b'entry')
            block.end_with_return(ctxt.new_binary_op(gccjit.BinaryOp.MULT,
                                                     ctxt.get_type(gccjit.TypeKind.INT),
                                                     param_i, param_i))

        for i in range(5):
            ctxt = gccjit.Context()
            cb(ctxt)

            if 0:
                ctxt.set_bool_option(gccjit.BoolOption.DUMP_INITIAL_TREE, True)
                ctxt.set_bool_option(gccjit.BoolOption.DUMP_INITIAL_GIMPLE, True)
            if 0:
                ctxt.set_int_option(gccjit.IntOption.OPTIMIZATION_LEVEL, 0)
            result = ctxt.compile()
            code = int_int_func_type(result.get_code(b"square"))
            self.assertEqual(code(5), 25)

    def test_sum_of_squares(self):
        def cb(ctxt):
            """
            Create this function:
              int loop_test (int n)
              {
                int i = 0;
                int sum = 0;
                while (i < n)
                {
                  sum += i * i;
                  i++;
                }
                return sum;
              }
            """
            the_type = ctxt.get_type(gccjit.TypeKind.INT)
            return_type = the_type
            param_n = ctxt.new_param(the_type, b"n")
            fn = ctxt.new_function(gccjit.FunctionKind.EXPORTED,
                                   return_type,
                                   b"loop_test",
                                   [param_n])
            # Build locals
            local_i = fn.new_local(the_type, b"i")
            local_sum = fn.new_local(the_type, b"sum")

            entry_block = fn.new_block(b'entry')

            # sum = 0
            entry_block.add_assignment(local_sum, ctxt.zero(the_type))

            # i = 0
            entry_block.add_assignment(local_i, ctxt.zero(the_type))

            # block "cond:"
            cond_block = fn.new_block(b"cond")

            # FIXME: a bit strange to add a jump instead of fallthrough?
            entry_block.end_with_jump(cond_block)

            loop_block = fn.new_block(b"loop")
            after_loop_block = fn.new_block(b"after_loop")


            # while (i < n)
            cond_block.end_with_conditional(ctxt.new_comparison(gccjit.Comparison.LT,
                                                                 local_i, param_n),
                                            loop_block,
                                            after_loop_block)

            # sum += i * i
            loop_block.add_assignment_op(local_sum,
                                         gccjit.BinaryOp.PLUS,
                                         ctxt.new_binary_op(gccjit.BinaryOp.MULT,
                                                            the_type,
                                                            local_i, local_i))

            # i++
            loop_block.add_assignment_op(local_i,
                                         gccjit.BinaryOp.PLUS,
                                         ctxt.one(the_type))

            # goto cond_block
            loop_block.end_with_jump(cond_block)

            # return sum
            after_loop_block.end_with_return(local_sum)

        for i in range(5):
            ctxt = gccjit.Context()
            cb(ctxt)
            if 0:
                ctxt.set_bool_option(gccjit.BoolOption.DUMP_INITIAL_TREE, True)
                ctxt.set_bool_option(gccjit.BoolOption.DUMP_INITIAL_GIMPLE, True)
                ctxt.set_bool_option(gccjit.BoolOption.DUMP_EVERYTHING, True)
                ctxt.set_bool_option(gccjit.BoolOption.KEEP_INTERMEDIATES, True)
            if 0:
                ctxt.set_int_option(gccjit.IntOption.OPTIMIZATION_LEVEL, 3)
            result = ctxt.compile()
            code = int_int_func_type(result.get_code(b"loop_test"))
            self.assertEqual(code(10), 285)

    def test_imported_function(self):
        """
        void some_fn (const char *name)
        {
            static char buffer[1024];
            snprintf(buffer, sizeof(buffer), "hello %s\n", name);
        }
        """
        ctxt = gccjit.Context()

        void_type = ctxt.get_type(gccjit.TypeKind.VOID)
        const_char_p = ctxt.get_type(gccjit.TypeKind.CONST_CHAR_PTR)
        char_type = ctxt.get_type(gccjit.TypeKind.CHAR)
        char_p = char_type.get_pointer()
        int_type = ctxt.get_type(gccjit.TypeKind.INT)
        size_type = ctxt.get_type(gccjit.TypeKind.SIZE_T)
        buf_type = ctxt.new_array_type(char_type, 1024)

        # extern int snprintf(char *str, size_t size, const char *format, ...);
        snprintf = ctxt.new_function(gccjit.FunctionKind.IMPORTED,
                                     int_type,
                                     b'snprintf',
                                     [ctxt.new_param(char_p, b's'),
                                      ctxt.new_param(size_type, b'n'),
                                      ctxt.new_param(const_char_p, b'format')],
                                     is_variadic=True)

        # void some_fn (const char *name) {
        param_name = ctxt.new_param(const_char_p, b'name')
        func = ctxt.new_function(gccjit.FunctionKind.EXPORTED,
                                 void_type,
                                 b'some_fn',
                                 [param_name])

        # static char buffer[1024];
        buffer = func.new_local(buf_type, b'buffer')

        # snprintf(buffer, sizeof(buffer), "hello %s\n", name);
        args = [ctxt.new_cast(buffer.get_address(), char_p),
                ctxt.new_rvalue_from_int(size_type, 1024),
                ctxt.new_string_literal(b'hello %s\n'),
                param_name.as_rvalue()]

        block = func.new_block(b'entry')
        block.add_eval(ctxt.new_call(snprintf, args))
        block.end_with_void_return()

        result = ctxt.compile()
        py_func_type = ctypes.CFUNCTYPE(None, ctypes.c_char_p)
        py_func = py_func_type(result.get_code(b'some_fn'))
        py_func(b'blah')


if __name__ == '__main__':
    unittest.main()
