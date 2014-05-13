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

Creating a trivial machine code function
----------------------------------------
Consider this C function:

 .. code-block:: c

   int square(int i)
   {
     return i * i;
   }

How can we construct this from within Python using libgccjit?

First we need to import the Python bindings to libgccjit:

>>> import gccjit

All state associated with compilation is associated with a
:py:class:`gccjit.Context`:

>>> ctxt = gccjit.Context()

The JIT library has a system of types.  It is statically-typed: every
expression is of a specific type, fixed at compile-time.  In our example,
all of the expressions are of the C `int` type, so let's obtain this from
the context, as a :py:class:`gccjit.Type`:

>>> int_type = ctxt.get_type(gccjit.TypeKind.INT)

The various objects in the API have reasonable `__str__` methods:

>>> print(int_type)
int

Let's create the function.  To do so, we first need to construct
its single parameter, specifying its type and giving it a name:

>>> param_i = ctxt.new_param(int_type, b'i')
>>> print(param_i)
i

Now we can create the function:

>>> fn = ctxt.new_function(gccjit.FunctionKind.EXPORTED,
...                        int_type, # return type
...                        b"square", # name
...                        [param_i]) # params
>>> print(fn)
square

To define the code within the function, we must create basic blocks
containing statements.

Every basic block contains a list of statements, eventually terminated
by a statement that either returns, or jumps to another basic block.

Our function has no control-flow, so we just need one basic block:

>>> block = fn.new_block(b'entry')
>>> print(block)
entry

Our basic block is relatively simple: it immediately terminates by
returning the value of an expression.  We can build the expression:

>>> expr = ctxt.new_binary_op(gccjit.BinaryOp.MULT,
...                           int_type,
...                           param_i, param_i)
>>> print(expr)
i * i

This in itself doesn't do anything; we have to add this expression to
a statement within the block.  In this case, we use it to build a
return statement, which terminates the basic block:

>>> block.end_with_return(expr)

OK, we've populated the context.  We can now compile it:

>>> jit_result = ctxt.compile()

and get a :py:class:`gccjit.Result`.

We can now look up a specific machine code routine within the result,
in this case, the function we created above:

>>> void_ptr = jit_result.get_code(b"square")

We can now use ctypes.CFUNCTYPE to turn it into something we can call
from Python:

>>> import ctypes
>>> int_int_func_type = ctypes.CFUNCTYPE(ctypes.c_int, ctypes.c_int)
>>> callable = int_int_func_type(void_ptr)

It should now be possible to run the code:

>>> callable(5)
25

Options
*******

To get more information on what's going on, you can set debugging flags
on the context using :py:meth:`gccjit.Context.set_bool_option`.

.. (I'm deliberately not mentioning
    :py:data:`gccjit.BoolOption.DUMP_INITIAL_TREE` here since I think
    it's probably more of use to implementors than to users)

Setting :py:data:`gccjit.BoolOption.DUMP_INITIAL_GIMPLE` will dump a
C-like representation to stderr when you compile (GCC's "GIMPLE"
representation)::

  >>> ctxt.set_bool_option(gccjit.BoolOption.DUMP_INITIAL_GIMPLE, True)
  >>> jit_result = ctxt.compile()
  square (signed int i)
  {
    signed int D.260;

    entry:
    D.260 = i * i;
    return D.260;
  }

We can see the generated machine code in assembler form (on stderr) by
setting :py:data:`gccjit.BoolOption.DUMP_GENERATED_CODE` on the context
before compiling:

>>> ctxt.set_bool_option(gccjit.BoolOption.DUMP_GENERATED_CODE, True)
>>> jit_result = ctxt.compile()
        .file   "fake.c"
        .text
        .globl  square
        .type   square, @function
square:
.LFB6:
        .cfi_startproc
        pushq   %rbp
        .cfi_def_cfa_offset 16
        .cfi_offset 6, -16
        movq    %rsp, %rbp
        .cfi_def_cfa_register 6
        movl    %edi, -4(%rbp)
.L14:
        movl    -4(%rbp), %eax
        imull   -4(%rbp), %eax
        popq    %rbp
        .cfi_def_cfa 7, 8
        ret
        .cfi_endproc
.LFE6:
        .size   square, .-square
        .ident  "GCC: (GNU) 4.9.0 20131023 (Red Hat 0.2-0.5.1920c315ff984892399893b380305ab36e07b455.fc20)"
        .section       .note.GNU-stack,"",@progbits

By default, no optimizations are performed, the equivalent of GCC's
`-O0` option.  We can turn things up to e.g. `-O3` by calling
:py:meth:`gccjit.Context.set_int_option` with
:py:data:`gccjit.IntOption.OPTIMIZATION_LEVEL`:

>>> ctxt.set_int_option(gccjit.IntOption.OPTIMIZATION_LEVEL, 3)
>>> jit_result = ctxt.compile()
        .file   "fake.c"
        .text
        .p2align 4,,15
        .globl  square
        .type   square, @function
square:
.LFB7:
        .cfi_startproc
.L16:
        movl    %edi, %eax
        imull   %edi, %eax
        ret
        .cfi_endproc
.LFE7:
        .size   square, .-square
        .ident  "GCC: (GNU) 4.9.0 20131023 (Red Hat 0.2-0.5.1920c315ff984892399893b380305ab36e07b455.fc20)"
        .section        .note.GNU-stack,"",@progbits

Naturally this has only a small effect on such a trivial function.


Full example
************

Here's what the above looks like as a complete program:

   .. literalinclude:: ../examples/square.py
    :lines: 27-
    :language: python
