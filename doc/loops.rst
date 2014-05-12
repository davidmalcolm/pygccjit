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

Loops and variables
-------------------
Consider this C function:

 .. code-block:: c

  int loop_test (int n)
  {
    int sum = 0;
    for (int i = 0; i < n; i++)
      sum += i * i;
    return sum;
  }

This example demonstrates some more features of libgccjit, with local
variables and a loop.

Let's construct this from Python.  To break this down into libgccjit
terms, it's usually easier to reword the `for` loop as a `while` loop,
giving:

 .. code-block:: c

  int loop_test (int n)
  {
    int sum = 0;
    int i = 0;
    while (i < n)
    {
      sum += i * i;
      i++;
    }
    return sum;
  }

Here's what the final control flow graph will look like:

    .. figure:: sum-of-squares.png
      :alt: image of a control flow graph

As before, we import the libgccjit Python bindings and make a
:py:class:`gccjit.Context`:

>>> import gccjit
>>> ctxt = gccjit.Context()

The function works with the C `int` type:

>>> the_type = ctxt.get_type(gccjit.TypeKind.INT)

though we could equally well make it work on, say, `double`:

>>> the_type = ctxt.get_type(gccjit.TypeKind.DOUBLE)

Let's build the function:

>>> return_type = the_type
>>> param_n = ctxt.new_param(the_type, b"n")
>>> fn = ctxt.new_function(gccjit.FunctionKind.EXPORTED,
...                        return_type,
...                        b"loop_test",
...                        [param_n])
>>> print(fn)
loop_test

The base class of expression is the :py:class:`gccjit.RValue`,
representing an expression that can be on the *right*-hand side of
an assignment: a value that can be computed somehow, and assigned
*to* a storage area (such as a variable).  It has a specific
:py:class:`gccjit.Type`.

Anothe important class is :py:class:`gccjit.LValue`.
A :py:class:`gccjit.LValue` is something that can of the *left*-hand
side of an assignment: a storage area (such as a variable).

In other words, every assignment can be thought of as:

 .. code-block:: c

   LVALUE = RVALUE;

Note that :py:class:`gccjit.LValue` is a subclass of
:py:class:`gccjit.RValue`, where in an assignment of the form:

 .. code-block:: c

   LVALUE_A = LVALUE_B;

the `LVALUE_B` implies reading the current value of that storage
area, assigning it into the `LVALUE_A`.

So far the only expressions we've seen are `i * i`::

    ctxt.new_binary_op(gccjit.BinaryOp.MULT,
                       int_type,
                       param_i, param_i)

which is a :py:class:`gccjit.RValue`, and the various function
parameters: `param_i` and `param_n`, instances of
:py:class:`gccjit.Param`, which is a subclass of
:py:class:`gccjit.LValue` (and, in turn, of :py:class:`gccjit.RValue`):
we can both read from and write to function parameters within the
body of a function.

Our new example has a couple of local variables.  We create them by
calling :py:meth:`gccjit.Function.new_local`, supplying a type and a name:

>>> local_i = fn.new_local(the_type, b"i")
>>> print(local_i)
i
>>> local_sum = fn.new_local(the_type, b"sum")
>>> print(local_sum)
sum

These are instances of :py:class:`gccjit.LValue` - they can be read from
and written to.

Note that there is no precanned way to create *and* initialize a variable
like in C:

.. code-block:: c

   int i = 0;

Instead, having added the local to the function, we have to separately add
an assignment of `0` to `local_i` at the beginning of the function.

This function has a loop, so we need to build some basic blocks to
handle the control flow.  In this case, we need 4 blocks:

1. before the loop (initializing the locals)
2. the conditional at the top of the loop (comparing `i < n`)
3. the body of the loop
4. after the loop terminates (`return sum`)

so we create these as :py:class:`gccjit.Block` instances within the
:py:class:`gccjit.Function`:

>>> entry_block = fn.new_block(b'entry')
>>> cond_block = fn.new_block(b"cond")
>>> loop_block = fn.new_block(b"loop")
>>> after_loop_block = fn.new_block(b"after_loop")

We now populate each block with statements.

The entry block consists of initializations followed by a jump to the
conditional.  We assign `0` to `i` and to `sum`, using
:py:meth:`gccjit.Block.add_assignment` to add
an assignment statement, and using :py:meth:`gccjit.Context.zero` to
get the constant value `0` for the relevant type for the right-hand side
of the assignment:

>>> entry_block.add_assignment(local_i, ctxt.zero(the_type))
>>> entry_block.add_assignment(local_sum, ctxt.zero(the_type))

We can then terminate the entry block by jumping to the conditional:

>>> entry_block.end_with_jump(cond_block)

The conditional block is equivalent to the line `while (i < n)` from our
C example. It contains a single statement: a conditional, which jumps to
one of two destination blocks depending on a boolean
:py:class:`gccjit.RValue`, in this case the comparison of `i` and `n`.
We build the comparison using :py:meth:`gccjit.Context.new_comparison`:

>>> guard = ctxt.new_comparison(gccjit.Comparison.LT, local_i, param_n)
>>> print(guard)
i < n

and can then use this to add `cond_block`'s sole statement, via
:py:meth:`gccjit.Block.end_with_conditional`:

>>> cond_block.end_with_conditional(guard,
...                                 loop_block, # on true
...                                 after_loop_block) # on false

Next, we populate the body of the loop.

The C statement `sum += i * i;` is an assignment operation, where an
lvalue is modified "in-place".  We use
:py:meth:`gccjit.Block.add_assignment_op` to handle these operations:

>>> loop_block.add_assignment_op(local_sum,
...                              gccjit.BinaryOp.PLUS,
...                              ctxt.new_binary_op(gccjit.BinaryOp.MULT,
...                                                 the_type,
...                                                 local_i, local_i))

The `i++` can be thought of as `i += 1`, and can thus be handled in
a similar way.  We use :py:meth:`gccjit.Context.one` to get the constant
value `1` (for the relevant type) for the right-hand side
of the assignment:

>>> loop_block.add_assignment_op(local_i,
...                              gccjit.BinaryOp.PLUS,
...                              ctxt.one(the_type))

The loop body completes by jumping back to the conditional:

>>> loop_block.end_with_jump(cond_block)

Finally, we populate the `after_loop` block, reached when the loop
conditional is false.  At the C level this is simply:

.. code-block:: c

   return sum;

so the block is just one statement:

>>> after_loop_block.end_with_return(local_sum)

.. note::

   You can intermingle block creation with statement creation,
   but given that the terminator statements generally include references
   to other blocks, I find it's clearer to create all the blocks,
   *then* all the statements.

We've finished populating the function.  As before, we can now compile it
to machine code:

>>> jit_result = ctxt.compile()
>>> void_ptr = jit_result.get_code(b'loop_test')

and use `ctypes` to turn it into a Python callable:

>>> import ctypes
>>> int_int_func_type = ctypes.CFUNCTYPE(ctypes.c_int, ctypes.c_int)
>>> callable = int_int_func_type(void_ptr)

Now we can call it:

>>> callable(10)
285

Visualizing the control flow graph
**********************************

You can see the control flow graph of a function using
:py:meth:`gccjit.Function.dump_to_dot`:

>>> fn.dump_to_dot('/tmp/sum-of-squares.dot')

giving a .dot file in GraphViz format.

You can convert this to an image using `dot`:

.. code-block:: bash

   $ dot -Tpng /tmp/sum-of-squares.dot -o /tmp/sum-of-squares.png

or use a viewer (my preferred one is xdot.py; see
https://github.com/jrfonseca/xdot.py; on Fedora you can
install it with `yum install python-xdot`):

    .. figure:: sum-of-squares.png
      :alt: image of a control flow graph

Full example
************

Here's what the above looks like as a complete program:

   .. literalinclude:: ../examples/sum_of_squares.py
    :lines: 34-
    :language: python
