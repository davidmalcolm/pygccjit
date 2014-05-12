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

   .. py:method:: new_local(type_, name, loc=None)

      Add a new local variable to the function::

        i = fn.new_local(int_type, b'i')

      :rtype: :py:class:`gccjit.LValue`

   .. py:method:: new_block(name)

      Create a :py:class:`gccjit.Block`.

      The name can be None, or you can give it a meaningful name, which
      may show up in dumps of the internal representation, and in error
      messages::

        entry = fn.new_block('entry')
        on_true = fn.new_block('on_true')

   .. py:method:: get_param(index)

      ..
        """get_param(index:int) -> Param"""

   .. py:method:: dump_to_dot(path)

      Write a dump in GraphViz format to the given path.

.. py:class:: gccjit.Block

   A `gccjit.Block` is a basic block within a function, i.e.
   a sequence of statements with a single entry point and a single
   exit point.

   The first basic block that you create within a function will
   be the entrypoint.

   Each basic block that you create within a function must be
   terminated, either with a conditional, a jump, or a return.

   It's legal to have multiple basic blocks that return within
   one function.

   .. py:method:: add_eval(rvalue, loc=None)

      Add evaluation of an rvalue, discarding the result
      (e.g. a function call that "returns" void), for example::

        call = ctxt.new_call(some_fn, args)
        block.add_eval(call)

      This is equivalent to this C code:

      .. code-block:: c

         (void)expression;

   .. py:method:: add_assignment(lvalue, rvalue, loc=None)

      Add evaluation of an rvalue, assigning the result to the given
      lvalue, for example::

            # i = 0
            entry_block.add_assignment(local_i, ctxt.zero(the_type))

      This is roughly equivalent to this C code:

      .. code-block:: c

         lvalue = rvalue;

   .. py:method:: add_assignment_op(lvalue, op, rvalue, loc=None)

      Add evaluation of an rvalue, using the result to modify an
      lvalue via the given :py:data:`gccjit.BinaryOp`.  For example::

        # i++
        loop_block.add_assignment_op(local_i,
                                     gccjit.BinaryOp.PLUS,
                                     ctxt.one(the_type))

      This is analogous to "+=" and friends:

      .. code-block:: c

         lvalue += rvalue;
         lvalue *= rvalue;
         lvalue /= rvalue;
         /* etc */

   .. py:method:: add_comment(text, Location loc=None)

      Add a no-op textual comment to the internal representation of the
      code.  It will be optimized away, but will be visible in the dumps
      seen via :py:data:`gccjit.BoolOption.DUMP_INITIAL_TREE`
      and :py:data:`gccjit.BoolOption.DUMP_INITIAL_GIMPLE`
      and thus may be of use when debugging how your project's internal
      representation gets converted to the libgccjit IR.

   .. py:method:: end_with_conditional(boolval, \
                                       on_true, \
                                       on_false=None, \
                                       loc=None)

      Terminate a block by adding evaluation of an rvalue, branching on the
      result to the appropriate successor block.

      This is roughly equivalent to this C code:

      .. code-block:: c

        if (boolval)
          goto on_true;
        else
          goto on_false;

      Example::

        # while (i < n)
        cond_block.end_with_conditional(
          ctxt.new_comparison(gccjit.Comparison.LT, local_i, param_n),
          loop_block,
          after_loop_block)

   .. py:method:: end_with_jump(target, loc=None)

      Terminate a block by adding a jump to the given target block.

      This is roughly equivalent to this C code:

      .. code-block:: c

         goto target;

      Example::

        loop_block.end_with_jump(cond_block)

   .. py:method:: end_with_return(RValue rvalue, loc=None)

      Terminate a block by adding evaluation of an rvalue, returning the
      value.

      This is roughly equivalent to this C code:

      .. code-block:: c

        return expression;

      Example::

        # return sum
        after_loop_block.end_with_return(local_sum)

   .. py:method:: end_with_void_return(loc=None)

      Terminate a block by adding a valueless return, for use within a function
      with "void" return type.

      This is equivalent to this C code:

      .. code-block:: c

        return;

   .. py:method:: get_function()

      Get the :py:class:`gccjit.Function` that this block is within.

.. py:class:: gccjit.FunctionKind

  .. py:data:: EXPORTED
  .. py:data:: INTERNAL
  .. py:data:: IMPORTED
  .. py:data:: ALWAYS_INLINE

