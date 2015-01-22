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

Source Locations
================

.. py:class:: gccjit.Location

   A `gccjit.Location` encapsulates a source code location, so that
   you can (optionally) associate locations in your language with
   statements in the JIT-compiled code, allowing the debugger to
   single-step through your language.

   You can construct them using :py:meth:`gccjit.Context.new_location()`.

   You need to enable :py:data:`gccjit.BoolOption.DEBUGINFO` on the
   :py:class:`gccjit.Context` for these locations to actually be usable by
   the debugger::

     ctxt.set_bool_option(gccjit.BoolOption.DEBUGINFO, True)

   `gccjit.Location` instances are optional; most API entrypoints
   accepting one default to `None`.

Faking it
---------
If you don't have source code for your internal representation, but need
to debug, you can generate a C-like representation of the functions in
your context using :py:meth:`gccjit.Context.dump_to_file()`::

   ctxt.dump_to_file(b'/tmp/something.c', True)

This will dump C-like code to the given path.  If the `update_locations`
argument is `True`, this will also set up `gccjit.Location` information
throughout the context, pointing at the dump file as if it
were a source file, giving you *something* you can step through in the
debugger.
