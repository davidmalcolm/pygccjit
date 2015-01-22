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

"""
This examples creates and runs the equivalent of this C function:

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

import ctypes

import gccjit

def populate_ctxt(ctxt):
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

    assert str(local_i) == 'i'

    # Build blocks
    entry_block = fn.new_block(b'entry')
    cond_block = fn.new_block(b"cond")
    loop_block = fn.new_block(b"loop")
    after_loop_block = fn.new_block(b"after_loop")

    # entry_block: #########################################

    # sum = 0
    entry_block.add_assignment(local_sum, ctxt.zero(the_type))

    # i = 0
    entry_block.add_assignment(local_i, ctxt.zero(the_type))

    entry_block.end_with_jump(cond_block)

    ### cond_block: ########################################

    # while (i < n)
    cond_block.end_with_conditional(ctxt.new_comparison(gccjit.Comparison.LT,
                                                         local_i, param_n),
                                    loop_block,
                                    after_loop_block)

    ### loop_block: ########################################

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

    ### after_loop_block: ##################################

    # return sum
    after_loop_block.end_with_return(local_sum)

def create_fn():
    # Create a compilation context:
    ctxt = gccjit.Context()

    if 0:
        ctxt.set_bool_option(gccjit.BoolOption.DUMP_INITIAL_TREE, True)
        ctxt.set_bool_option(gccjit.BoolOption.DUMP_INITIAL_GIMPLE, True)
        ctxt.set_bool_option(gccjit.BoolOption.DUMP_EVERYTHING, True)
        ctxt.set_bool_option(gccjit.BoolOption.KEEP_INTERMEDIATES, True)
    if 0:
        ctxt.set_int_option(gccjit.IntOption.OPTIMIZATION_LEVEL, 3)

    populate_ctxt(ctxt)

    jit_result = ctxt.compile()
    return jit_result

def test_calling_fn(i):
    jit_result = create_fn()

    int_int_func_type = ctypes.CFUNCTYPE(ctypes.c_int, ctypes.c_int)
    code = int_int_func_type(jit_result.get_code(b"loop_test"))

    return code(i)

if __name__ == '__main__':
    print(test_calling_fn(10))
