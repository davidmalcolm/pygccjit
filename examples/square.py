#   Copyright 2014 David Malcolm <dmalcolm@redhat.com>
#   Copyright 2014 Red Hat, Inc.
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

"""
This examples creates and runs the equivalent of this C function:

  int square(int i)
  {
    return i * i;
  }
"""

import ctypes

import gccjit

def create_fn():
    # Create a compilation context:
    ctxt = gccjit.Context()

    # Turn these on to get various kinds of debugging:
    if 0:
        ctxt.set_bool_option(gccjit.BoolOption.DUMP_INITIAL_TREE, True)
        ctxt.set_bool_option(gccjit.BoolOption.DUMP_INITIAL_GIMPLE, True)
        ctxt.set_bool_option(gccjit.BoolOption.DUMP_GENERATED_CODE, True)

    # Adjust this to control optimization level of the generated code:
    if 0:
        ctxt.set_int_option(gccjit.IntOption.OPTIMIZATION_LEVEL, 3)

    int_type = ctxt.get_type(gccjit.TypeKind.INT)

    # Create parameter "i":
    param_i = ctxt.new_param(int_type, b'i')
    # Create the function:
    fn = ctxt.new_function(gccjit.FunctionKind.EXPORTED,
                           int_type,
                           b"square",
                           [param_i])

    # Create a basic block within the function:
    block = fn.new_block(b'entry')

    # This basic block is relatively simple:
    block.end_with_return(
        ctxt.new_binary_op(gccjit.BinaryOp.MULT,
                           int_type,
                           param_i, param_i))

    # Having populated the context, compile it.
    jit_result = ctxt.compile()

    # This is what you get back from ctxt.compile():
    assert isinstance(jit_result, gccjit.Result)

    return jit_result

def test_calling_fn(i):
    jit_result = create_fn()

    # Look up a specific machine code routine within the gccjit.Result,
    # in this case, the function we created above:
    void_ptr = jit_result.get_code(b"square")

    # Now use ctypes.CFUNCTYPE to turn it into something we can call
    # from Python:
    int_int_func_type = ctypes.CFUNCTYPE(ctypes.c_int, ctypes.c_int)
    code = int_int_func_type(void_ptr)

    # Now try running the code:
    return code(i)

if __name__ == '__main__':
    print(test_calling_fn(5))
