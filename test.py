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

import gccjit

def cb(ctxt):
    """
    Create this function:
      int square(int i)
      {
         return i * i;
      }
    """
    param_i = ctxt.new_param(None,
                             ctxt.get_int_type(),
                             b'i')
    fn = ctxt.new_function(None,
                           gccjit.FUNCTION_EXPORTED,
                           ctxt.get_int_type(),
                           b"square",
                           [param_i])
    fn.add_return(None,
                  ctxt.new_binary_op(None,
                                     gccjit.BINARY_OP_MULT,
                                     ctxt.get_int_type(),
                                     param_i, param_i))

for i in range(5):
    ctxt = gccjit.Context(cb)
    if 0:
        ctxt.set_bool_option(gccjit.BOOL_OPTION_DUMP_INITIAL_TREE, True)
        ctxt.set_bool_option(gccjit.BOOL_OPTION_DUMP_INITIAL_GIMPLE, True)
    if 0:
        ctxt.set_int_option(gccjit.INT_OPTION_OPTIMIZATION_LEVEL, 0)
    result = ctxt.compile()
    code = result.get_code(b"square")
    print('code(5) = %s' % code(5))
