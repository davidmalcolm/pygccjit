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
