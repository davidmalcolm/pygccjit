.. Copyright 2014 David Malcolm <dmalcolm@redhat.com>
   Copyright 2014 Red Hat, Inc.

   This is free software: you can redistribute it and/or modify it
   under the terms of the GNU General Public License as published by
   the Free Software Foundation, either version 3 of the License, or
   (at your option) any later version.

   This program is distributed in the hope that it will be useful, but
   WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
   General Public License for more details.

   You should have received a copy of the GNU General Public License
   along with this program.  If not, see
   <http://www.gnu.org/licenses/>.

Functions
=========
.. py:class:: gccjit.Param

.. py:class:: gccjit.Function

   .. py:method:: new_local(Type type_, name, Location loc=None)

      ..
        """new_local(type_:Type, name:str, loc:Location=None) -> LValue"""

   .. py:method:: new_block(name)

      ..
        """new_block(name:str) -> Block"""

   .. py:method:: get_param(index)

      ..
        """get_param(index:int) -> Param"""

   .. py:method:: dump_to_dot(path)

      ..
        """dump_to_dot(path:str)"""

.. py:class:: gccjit.Block

   .. py:method:: add_eval(RValue rvalue, Location loc=None)

      ..
        """add_eval(rvalue:RValue, loc:Location=None)"""

   .. py:method:: add_assignment(LValue lvalue, RValue rvalue, Location loc=None)

      ..
        """add_assignment(lvalue:LValue, rvalue:RValue, loc:Location=None)"""

   .. py:method:: add_assignment_op(LValue lvalue, op, RValue rvalue, Location loc=None)

      ..
        """add_assignment(lvalue:LValue, op:BinaryOp, rvalue:RValue, loc:Location=None)"""

   .. py:method:: add_comment(text, Location loc=None)

      ..
        """add_comment(text:str, loc:Location=None)"""

   .. py:method:: end_with_conditional(RValue boolval, \
                             Block on_true, \
                             Block on_false=None, \
                             Location loc=None)

      ..
        """end_with_conditional(on_true:Block, on_false:Block=None, loc:Location=None)"""

   .. py:method:: end_with_jump(Block target, Location loc=None)

      ..
        """end_with_jump(target:Block, loc:Location=None)"""

   .. py:method:: end_with_return(RValue rvalue, loc=None)

      ..
        """end_with_return(rvalue:RValue, loc:Location=None)"""

   .. py:method:: end_with_void_return(loc=None)

      ..
        """end_with_void_return(loc:Location=None)"""

   .. py:method:: get_function()

      ..
        """get_function(self) -> Function"""
        c_function = c_api.gcc_jit_block_get_function (self._get_c_block())
        return Function_from_c(c_function)


.. py:class:: gccjit.FunctionKind

  .. py:data:: EXPORTED
  .. py:data:: INTERNAL
  .. py:data:: IMPORTED
  .. py:data:: ALWAYS_INLINE

