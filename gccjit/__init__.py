#   Copyright 2014 Simon Feltman <s.feltman@gmail.com>
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

from __future__ import absolute_import

from ._gccjit import (Context,
                      Object,
                      Result,
                      RValue,
                      LValue,
                      Type,
                      Location,
                      Field,
                      Struct,
                      Param,
                      Function,
                      Block,
                      FunctionKind,
                      UnaryOp,
                      BinaryOp,
                      Comparison,
                      StrOption,
                      IntOption,
                      BoolOption,
                      OutputKind,
                      TypeKind,
                      GlobalKind,
                      Error,
                      )

# Make it easy to make a "main" function:

def make_main(ctxt):
    """
    Make "main" function:
      int
      main (int argc, char **argv)
      {
      ...
      }
    Return (func, param_argc, param_argv)
    """
    int_type = ctxt.get_type(TypeKind.INT)
    param_argc = ctxt.new_param(int_type, b"argc")
    char_ptr_ptr_type = (
        ctxt.get_type(TypeKind.CHAR).get_pointer().get_pointer())
    param_argv = ctxt.new_param(char_ptr_ptr_type, b"argv")
    func_main = ctxt.new_function(FunctionKind.EXPORTED,
                                  int_type,
                                  b"main",
                                  [param_argc, param_argv])
    return (func_main, param_argc, param_argv)
