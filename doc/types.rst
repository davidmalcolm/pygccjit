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

Types
=====

Types can be created in several ways:

* fundamental types can be accessed using
  :py:meth:`gccjit.Context.get_type`::

      int_type = ctxt.get_type(gccjit.TypeKind.INT)

  See :py:class:`gccjit.TypeKind` for the available types.

  You can `int` types of specific sizes (in bytes) using
  :py:meth:`gccjit.Context.get_int_type`::

      int_type = ctxt.get_int_type(4, is_signed=True)

* derived types can be accessed by calling methods on an existing
  type::

    const_int_star = int_type.get_const().get_pointer()
    int_const_star = int_type.get_pointer().get_const()

* by creating structures (see below).

.. py:class:: gccjit.Type

   .. py:method:: get_pointer()

       Given type `T` get type `T*`.

       :rtype: :py:class:`gccjit.Type`

   .. py:method:: get_const()

       Given type `T` get type `const T`.

       :rtype: :py:class:`gccjit.Type`

   .. py:method:: get_volatile()

       Given type `T` get type `volatile T`.

       :rtype: :py:class:`gccjit.Type`

Structures
----------

You can model C `struct` types by creating :py:class:`gccjit.Struct` and
:py:class:`gccjit.Field` instances, in either order:

* by creating the fields, then the structure.  For example, to model:

  .. code-block:: c

    struct coord {double x; double y; };

  you could call::

    field_x = ctxt.new_field(double_type, b'x')
    field_y = ctxt.new_field(double_type, b'y')
    coord = ctxt.new_struct(b'coord', [field_x, field_y])

  (see :py:meth:`gccjit.Context.new_field()` and
  :py:meth:`gccjit.Context.new_struct()`), or

* by creating the structure, then populating it with fields, typically
  to allow modelling self-referential structs such as:

  .. code-block:: c

    struct node { int m_hash; struct node *m_next; };

  like this::

    node = ctxt.new_struct(b'node')
    node_ptr = node.get_pointer()
    field_hash = ctxt.new_field(int_type, b'm_hash')
    field_next = ctxt.new_field(node_ptr, b'm_next')
    node.set_fields([field_hash, field_next])

  (see :py:meth:`gccjit.Struct.set_fields`)

.. py:class:: gccjit.Field

   .. TODO

.. py:class:: gccjit.Struct

   .. py:method:: set_fields(fields, loc=None)

      Populate the fields of a formerly-opaque struct type.
      This can only be called once on a given struct type.
