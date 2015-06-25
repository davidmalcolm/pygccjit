#   Copyright 2015 David Malcolm <dmalcolm@redhat.com>
#   Copyright 2015 Red Hat, Inc.
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

import ctypes

import gccjit

# Example of creating and running a switch statement

# Quote from here in docs/topics/functions.rst

def populate_ctxt(ctxt):
    """
    Creates the equivalent of this C function:

      int
      test_switch (int x)
      {
	switch (x)
	  {
	  case 0 ... 5:
	     return 3;

	  case 25 ... 27:
	     return 4;

	  case -42 ... -17:
	     return 83;

	  case 40:
	     return 8;

	  default:
	     return 10;
	  }
      }
    """
    t_int = ctxt.get_type(gccjit.TypeKind.INT)
    return_type = t_int
    param_x = ctxt.new_param(t_int, b"x")
    fn = ctxt.new_function(gccjit.FunctionKind.EXPORTED,
                           return_type,
                           b"test_switch",
                           [param_x])

    # Build blocks
    b_entry = fn.new_block(b'entry')
    b_case_0_5 = fn.new_block(b"b_case_0_5")
    b_case_25_27 = fn.new_block(b"b_case_25_27")
    b_case_m42_m17 = fn.new_block(b"b_case_m42_m17")
    b_case_40 = fn.new_block(b"b_case_40")
    b_default = fn.new_block(b"b_default")

    # entry_block: #########################################

    cases = [ctxt.new_case(ctxt.new_rvalue_from_int (t_int, lower),
                           ctxt.new_rvalue_from_int (t_int, upper),
                           destblock)
             for lower, upper, destblock in [ (0, 5, b_case_0_5),
                                              (25, 27, b_case_25_27),
                                              (-42, -17, b_case_m42_m17),
                                              (40, 40, b_case_40)]]

    b_entry.end_with_switch(param_x, b_default, cases)

    ### case blocks: ########################################

    b_case_0_5.end_with_return(ctxt.new_rvalue_from_int (t_int, 3))
    b_case_25_27.end_with_return(ctxt.new_rvalue_from_int (t_int, 4))
    b_case_m42_m17.end_with_return(ctxt.new_rvalue_from_int (t_int, 83))
    b_case_40.end_with_return(ctxt.new_rvalue_from_int (t_int, 8))
    b_default.end_with_return(ctxt.new_rvalue_from_int (t_int, 10))

# Quote up to here in docs/topics/functions.rst

def simulate_fn(x):
    """A Python reimplementation of our test function for testing it against"""
    if x >= 0 and x <= 5:
        return 3
    elif x >= 25 and x <= 27:
        return 4
    elif x >= -42 and x <= -17:
        return 83
    elif x == 40:
        return 8
    else:
        return 10

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

def compile_test_switch():
    jit_result = create_fn()

    int_int_func_type = ctypes.CFUNCTYPE(ctypes.c_int, ctypes.c_int)
    code = int_int_func_type(jit_result.get_code(b"test_switch"))

    return jit_result, code

if __name__ == '__main__':
    jit_result, test_switch = compile_test_switch()
    for i in range(-200, 200):
        print('test_switch(%i) == %i' % (i, test_switch(i)))
    del jit_result
