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

Expressions
===========

.. py:class:: gccjit.RValue

   .. py:method:: dereference_field(Field field, Location loc=None)

      ..
        """dereference_field(field:Field, loc:Location=None) -> LValue"""
        return LValue_from_c(c_api.gcc_jit_rvalue_dereference_field (self._get_c_rvalue(),
                                                                     get_c_location(loc),
                                                                     field._get_c_field()))
   .. py:method:: dereference(loc=None)

      ..
        """dereference(loc:Location=None) -> LValue"""
        return LValue_from_c(c_api.gcc_jit_rvalue_dereference (self._get_c_rvalue(),
                                                               get_c_location(loc)))

   .. py:method:: get_type()

      ..
        return Type_from_c(c_api.gcc_jit_rvalue_get_type (self._get_c_rvalue()))

.. py:class:: gccjit.LValue

   .. py:method:: get_address(loc=None)

      Get the address of this lvalue, as a :py:class:`gccjit.RValue` of
      type `T*`.

Unary Operations
****************

Unary operations are :py:class:`gccjit.RValue` instances
built using :py:meth:`gccjit.Context.new_unary_op`
with an operation from one of the following:

=========================================  ============
Unary Operation                            C equivalent
=========================================  ============
:py:data:`gccjit.UnaryOp.MINUS`            `-(EXPR)`
:py:data:`gccjit.UnaryOp.BITWISE_NEGATE`   `~(EXPR)`
:py:data:`gccjit.UnaryOp.LOGICAL_NEGATE`   `!(EXPR)`
=========================================  ============

.. py:class:: gccjit.UnaryOp

   .. py:data:: MINUS

      Negate an arithmetic value; analogous to:

      .. code-block:: c

         -(EXPR)

      in C.

   .. py:data:: BITWISE_NEGATE

      Bitwise negation of an integer value (one's complement); analogous
      to:

      .. code-block:: c

         ~(EXPR)

      in C.

   .. py:data:: LOGICAL_NEGATE

      Logical negation of an arithmetic or pointer value; analogous to:

      .. code-block:: c

         !(EXPR)

      in C.

Binary Operations
*****************

Unary operations are :py:class:`gccjit.RValue` instances
built using :py:meth:`gccjit.Context.new_binary_op`
with an operation from one of the following:

=======================================  ============
Binary Operation                         C equivalent
=======================================  ============
:py:data:`gccjit.BinaryOp.PLUS`          `x + y`
:py:data:`gccjit.BinaryOp.MINUS`         `x - y`
:py:data:`gccjit.BinaryOp.MULT`          `x * y`
:py:data:`gccjit.BinaryOp.DIVIDE`        `x / y`
:py:data:`gccjit.BinaryOp.MODULO`        `x % y`
:py:data:`gccjit.BinaryOp.BITWISE_AND`   `x & y`
:py:data:`gccjit.BinaryOp.BITWISE_XOR`   `x ^ y`
:py:data:`gccjit.BinaryOp.BITWISE_OR`    `x | y`
:py:data:`gccjit.BinaryOp.LOGICAL_AND`   `x && y`
:py:data:`gccjit.BinaryOp.LOGICAL_OR`    `x || y`
=======================================  ============

.. py:class:: gccjit.BinaryOp

  .. py:data:: PLUS

     Addition of arithmetic values; analogous to:

     .. code-block:: c

       (EXPR_A) + (EXPR_B)

     in C.

     For pointer addition, use :py:meth:`gccjit.Context.new_array_access`.

  .. py:data:: MINUS

     Subtraction of arithmetic values; analogous to:

     .. code-block:: c

       (EXPR_A) - (EXPR_B)

     in C.

  .. py:data:: MULT

     Multiplication of a pair of arithmetic values; analogous to:

     .. code-block:: c

       (EXPR_A) * (EXPR_B)

     in C.

  .. py:data:: DIVIDE

     Quotient of division of arithmetic values; analogous to:

     .. code-block:: c

       (EXPR_A) / (EXPR_B)

     in C.

     The result type affects the kind of division: if the result type is
     integer-based, then the result is truncated towards zero, whereas
     a floating-point result type indicates floating-point division.

  .. py:data:: MODULO

     Remainder of division of arithmetic values; analogous to:

     .. code-block:: c

       (EXPR_A) % (EXPR_B)

     in C.

  .. py:data:: BITWISE_AND

     Bitwise AND; analogous to:

     .. code-block:: c

       (EXPR_A) & (EXPR_B)

     in C.

  .. py:data:: BITWISE_XOR

     Bitwise exclusive OR; analogous to:

     .. code-block:: c

        (EXPR_A) ^ (EXPR_B)

     in C.

  .. py:data:: BITWISE_OR

     Bitwise inclusive OR; analogous to:

     .. code-block:: c

       (EXPR_A) | (EXPR_B)

     in C.

  .. py:data:: LOGICAL_AND

     Logical AND; analogous to:

     .. code-block:: c

       (EXPR_A) && (EXPR_B)

     in C.

  .. py:data:: LOGICAL_OR

     Logical OR; analogous to:

     .. code-block:: c

       (EXPR_A) || (EXPR_B)

     in C.

Comparisons
***********

Comparisons are :py:class:`gccjit.RValue` instances of
boolean type built using :py:meth:`gccjit.Context.new_comparison`
with an operation from one of the following:

=======================================  ============
Comparison                               C equivalent
=======================================  ============
:py:data:`gccjit.Comparison.EQ`          `x == y`
:py:data:`gccjit.Comparison.NE`          `x != y`
:py:data:`gccjit.Comparison.LT`          `x < y`
:py:data:`gccjit.Comparison.LE`          `x <= y`
:py:data:`gccjit.Comparison.GT`          `x > y`
:py:data:`gccjit.Comparison.GE`          `x >= y`
=======================================  ============

.. py:class:: gccjit.Comparison

  .. py:data:: EQ

  .. py:data:: NE

  .. py:data:: LT

  .. py:data:: LE

  .. py:data:: GT

  .. py:data:: GE
