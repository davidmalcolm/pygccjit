.. Copyright 2015 David Malcolm <dmalcolm@redhat.com>
   Copyright 2015 Red Hat, Inc.

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

Implementing a "brainf" compiler
--------------------------------

In this example we use libgccjit to construct a compiler for an esoteric
programming language that we shall refer to as "brainf".

The compiler can run the generated code in-process (JIT compilation),
or write the generated code as a machine code executable (classic
ahead-of-time compilation).

The "brainf" language
*********************

brainf scripts operate on an array of bytes, with a notional data pointer
within the array.

brainf is hard for humans to read, but it's trivial to write a parser for
it, as there is no lexing; just a stream of bytes.  The operations are:

====================== =============================
Character              Meaning
====================== =============================
``>``                  ``idx += 1``
``<``                  ``idx -= 1``
``+``                  ``data[idx] += 1``
``-``                  ``data[idx] -= 1``
``.``                  ``output (data[idx])``
``,``                  ``data[idx] = input ()``
``[``                  loop until ``data[idx] == 0``
``]``                  end of loop
Anything else          ignored
====================== =============================

Unlike the previous example, we'll implement an ahead-of-time compiler,
which reads ``.bf`` scripts and outputs executables (though it would
be trivial to have it run them JIT-compiled in-process).

Here's what a simple ``.bf`` script looks like:

   .. literalinclude:: ../examples/emit-alphabet.bf
    :lines: 1-

.. note::

   This example makes use of whitespace and comments for legibility, but
   could have been written as::

     ++++++++++++++++++++++++++
     >+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++<
     [>.+<-]

   It's not a particularly useful language, except for providing
   compiler-writers with a test case that's easy to parse.

Converting a brainf script to libgccjit IR
******************************************

We write simple code to populate a :py:class:`gccjit.Context`.

   .. literalinclude:: ../examples/bf.py
    :start-after: import gccjit
    :end-before: def compile_to_file(self, output_path):
    :language: python

Compiling a context to a file
*****************************

Unlike the previous examples, this time we'll compile the context
directly to an executable, using :py:meth:`gccjit.Context.compile_to_file`:

.. code-block:: python

    def compile_to_file(self, output_path):
        self.ctxt.compile_to_file(gccjit.OutputKind.EXECUTABLE,
                                  output_path)

Here's the top-level of the compiler, which is what actually calls into
:c:func:`gcc_jit_context_compile_to_file`:

 .. literalinclude:: ../examples/bf.py
    :start-after: # Entrypoint
    :language: python

Note how once the context is populated you could trivially instead compile
it to memory using :py:meth:`gccjit.Context.compile` and run it in-process
as in the previous examples.

To create an executable, we need to export a ``main`` function.  A helper
function for doing so is provided by the JIT API:

 .. literalinclude:: ../gccjit/__init__.py
    :start-after: # Make it easy to make a "main" function:
    :language: python

The overall script `examples/bf.py` is thus a bf-to-machine-code compiler,
which we can use to compile .bf files into machine code executables:

.. code-block:: console

  $ PYTHONPATH=. python examples/bf.py \
       emit-alphabet.bf \
       a.out

which we can run directly:

.. code-block:: console

  $ ./a.out
  ABCDEFGHIJKLMNOPQRSTUVWXYZ

Success!

We can also inspect the generated executable using standard tools:

.. code-block:: console

  $ objdump -d a.out |less

which shows that libgccjit has managed to optimize the function
somewhat (for example, the runs of 26 and 65 increment operations
have become integer constants 0x1a and 0x41):

.. code-block:: console

  0000000000400620 <main>:
    400620:     80 3d 39 0a 20 00 00    cmpb   $0x0,0x200a39(%rip)        # 601060 <data
    400627:     74 07                   je     400630 <main
    400629:     eb fe                   jmp    400629 <main+0x9>
    40062b:     0f 1f 44 00 00          nopl   0x0(%rax,%rax,1)
    400630:     48 83 ec 08             sub    $0x8,%rsp
    400634:     0f b6 05 26 0a 20 00    movzbl 0x200a26(%rip),%eax        # 601061 <data_cells+0x1>
    40063b:     c6 05 1e 0a 20 00 1a    movb   $0x1a,0x200a1e(%rip)       # 601060 <data_cells>
    400642:     8d 78 41                lea    0x41(%rax),%edi
    400645:     40 88 3d 15 0a 20 00    mov    %dil,0x200a15(%rip)        # 601061 <data_cells+0x1>
    40064c:     0f 1f 40 00             nopl   0x0(%rax)
    400650:     40 0f b6 ff             movzbl %dil,%edi
    400654:     e8 87 fe ff ff          callq  4004e0 <putchar@plt>
    400659:     0f b6 05 01 0a 20 00    movzbl 0x200a01(%rip),%eax        # 601061 <data_cells+0x1>
    400660:     80 2d f9 09 20 00 01    subb   $0x1,0x2009f9(%rip)        # 601060 <data_cells>
    400667:     8d 78 01                lea    0x1(%rax),%edi
    40066a:     40 88 3d f0 09 20 00    mov    %dil,0x2009f0(%rip)        # 601061 <data_cells+0x1>
    400671:     75 dd                   jne    400650 <main+0x30>
    400673:     31 c0                   xor    %eax,%eax
    400675:     48 83 c4 08             add    $0x8,%rsp
    400679:     c3                      retq
    40067a:     66 0f 1f 44 00 00       nopw   0x0(%rax,%rax,1)

We also set up debugging information (via
:py:meth:`gccjit.Context.new_location` and
:py:data:`gccjit.BoolOption.DEBUGINFO`), so it's possible to use ``gdb``
to singlestep through the generated binary and inspect the internal
state ``idx`` and ``data_cells``:

.. code-block:: console

  (gdb) break main
  Breakpoint 1 at 0x400790
  (gdb) run
  Starting program: a.out

  Breakpoint 1, 0x0000000000400790 in main (argc=1, argv=0x7fffffffe448)
  (gdb) stepi
  0x0000000000400797 in main (argc=1, argv=0x7fffffffe448)
  (gdb) stepi
  0x00000000004007a0 in main (argc=1, argv=0x7fffffffe448)
  (gdb) stepi
  9     >+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++<
  (gdb) list
  4
  5     cell 0 = 26
  6     ++++++++++++++++++++++++++
  7
  8     cell 1 = 65
  9     >+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++<
  10
  11    while cell#0 != 0
  12    [
  13     >
  (gdb) n
  6     ++++++++++++++++++++++++++
  (gdb) n
  9     >+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++<
  (gdb) p idx
  $1 = 1
  (gdb) p data_cells
  $2 = "\032", '\000' <repeats 29998 times>
  (gdb) p data_cells[0]
  $3 = 26 '\032'
  (gdb) p data_cells[1]
  $4 = 0 '\000'
  (gdb) list
  4
  5     cell 0 = 26
  6     ++++++++++++++++++++++++++
  7
  8     cell 1 = 65
  9     >+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++<
  10
  11    while cell#0 != 0
  12    [
  13     >


Other forms of ahead-of-time-compilation
****************************************

The above demonstrates compiling a :py:class:`gccjit.Context` directly
to an executable.  It's also possible to compile it to an object file,
and to a dynamic library.  See the documentation of
:py:meth:`gccjit.Context.compile_to_file` for more information.
