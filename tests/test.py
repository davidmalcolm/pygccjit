#   Copyright 2013-2015 David Malcolm <dmalcolm@redhat.com>
#   Copyright 2013-2015 Red Hat, Inc.
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
        from examples.square import test_calling_fn
        for i in range(5):
            self.assertEqual(test_calling_fn(i), i * i)

    def test_sum_of_squares(self):
        from examples.sum_of_squares import test_calling_fn
        for i in range(5):
            self.assertEqual(test_calling_fn(i),
                             sum([j * j for j in range(i)]))

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
        call = ctxt.new_call(snprintf, args)
        self.assertEqual(call.get_type(), int_type)
        block.add_eval(call)
        block.end_with_void_return()

        result = ctxt.compile()
        py_func_type = ctypes.CFUNCTYPE(None, ctypes.c_char_p)
        py_func = py_func_type(result.get_code(b'some_fn'))
        py_func(b'blah')

    def test_opaque_struct(self):
        ctxt = gccjit.Context()
        foo = ctxt.new_struct(b'foo')
        foo_ptr = foo.get_pointer()
        self.assertEqual(str(foo_ptr), 'struct foo *')
        foo.set_fields([ctxt.new_field(foo_ptr, b'prev'),
                        ctxt.new_field(foo_ptr, b'next')])

    def test_rvalue_from_ptr(self):
        ctxt = gccjit.Context()
        type_ = ctxt.get_type(gccjit.TypeKind.CONST_CHAR_PTR)
        null_ptr = ctxt.new_rvalue_from_ptr(type_, 0)
        self.assertEqual(str(null_ptr), '(const char *)NULL')

        type_ = ctxt.get_type(gccjit.TypeKind.VOID_PTR)
        nonnull_ptr = ctxt.new_rvalue_from_ptr(type_, id(self))
        self.assertEqual(str(nonnull_ptr), '(void *)0x%x' % id(self))

    def test_dereference(self):
        ctxt = gccjit.Context()
        type_ = ctxt.get_type(gccjit.TypeKind.CONST_CHAR_PTR)
        nonnull_ptr = ctxt.new_rvalue_from_ptr(type_, id(self))
        self.assertEqual(str(nonnull_ptr.dereference()),
                         '*(const char *)0x%x' % id(self))

    def test_call_through_function_ptr(self):
        ctxt = gccjit.Context()
        void_type = ctxt.get_type(gccjit.TypeKind.VOID)
        int_type = ctxt.get_type(gccjit.TypeKind.INT)
        fn_ptr_type = ctxt.new_function_ptr_type (void_type,
                                                  [int_type,
                                                   int_type,
                                                   int_type])
        self.assertEqual(str(fn_ptr_type),
                         'void (*) (int, int, int)')
        fn_ptr = ctxt.new_param(fn_ptr_type, "fn")
        a = ctxt.new_param(int_type, "a")
        b = ctxt.new_param(int_type, "b")
        c = ctxt.new_param(int_type, "c")
        call = ctxt.new_call_through_ptr(fn_ptr, [a, b, c])
        self.assertEqual(str(call),
                         'fn (a, b, c)')

    def test_union(self):
        ctxt = gccjit.Context()
        int_type = ctxt.get_type(gccjit.TypeKind.INT)
        float_type = ctxt.get_type(gccjit.TypeKind.FLOAT)
        as_int = ctxt.new_field(int_type, b'as_int')
        as_float = ctxt.new_field(float_type, b'as_float')
        u = ctxt.new_union(b'u', [as_int, as_float])
        self.assertEqual(str(u), 'union u')

    def test_bf(self):
        from examples import bf
        c = bf.Compiler()
        c.compile_into_ctxt('examples/emit-alphabet.bf')
        c.compile_to_file('emit-alphabet.exe')

if __name__ == '__main__':
    unittest.main()
