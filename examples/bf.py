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

# A compiler for the "bf" language

import sys

import gccjit

class Paren:
    def __init__(self, b_test, b_body, b_after):
        self.b_test = b_test
        self.b_body = b_body
        self.b_after = b_after

class CompileError(Exception):
    def __init__(self, compiler, msg):
        self.filename = compiler.filename
        self.line = compiler.line
        self.column = compiler.column
        self.msg = msg

    def __str__(self):
        return ("%s:%i:%i: %s"
                % (self.filename, self.line, self.column, self.msg))

class Compiler:
    def __init__(self): #, filename):
        self.ctxt = gccjit.Context()
        if 1:
            self.ctxt.set_int_option(gccjit.IntOption.OPTIMIZATION_LEVEL,
                                     3);
            self.ctxt.set_bool_option(gccjit.BoolOption.DUMP_INITIAL_GIMPLE,
                                      0);
            self.ctxt.set_bool_option(gccjit.BoolOption.DUMP_GENERATED_CODE,
                                      0);
            self.ctxt.set_bool_option(gccjit.BoolOption.DEBUGINFO,
                                      1);
            self.ctxt.set_bool_option(gccjit.BoolOption.DUMP_EVERYTHING,
                                      0);
            self.ctxt.set_bool_option(gccjit.BoolOption.KEEP_INTERMEDIATES,
                                      0);
        self.void_type = self.ctxt.get_type(gccjit.TypeKind.VOID)
        self.int_type = self.ctxt.get_type(gccjit.TypeKind.INT)
        self.byte_type = self.ctxt.get_type(gccjit.TypeKind.UNSIGNED_CHAR)
        self.array_type = self.ctxt.new_array_type(self.byte_type,
                                                   30000)
        self.func_getchar = (
            self.ctxt.new_function(gccjit.FunctionKind.IMPORTED,
                                   self.int_type,
                                   b"getchar", []))
        self.func_putchar = (
            self.ctxt.new_function(gccjit.FunctionKind.IMPORTED,
                                   self.void_type,
                                   b"putchar",
                                   [self.ctxt.new_param(self.int_type,
                                                        b"c")]))
        self.func = self.ctxt.new_function(gccjit.FunctionKind.EXPORTED,
                                           self.void_type, b'func', [])
        self.curblock = self.func.new_block(b"initial")
        self.int_zero = self.ctxt.zero(self.int_type)
        self.int_one = self.ctxt.one(self.int_type)
        self.byte_zero = self.ctxt.zero(self.byte_type)
        self.byte_one = self.ctxt.one(self.byte_type)
        self.data_cells = self.ctxt.new_global(gccjit.GlobalKind.INTERNAL,
                                               self.array_type,
                                               b"data_cells")
        self.idx = self.func.new_local(self.int_type,
                                       b"idx")

        self.open_parens = []

        self.curblock.add_comment(b"idx = 0;")
        self.curblock.add_assignment(self.idx,
                                     self.int_zero)

    def get_current_data(self, loc):
        """Get 'data_cells[idx]' as an lvalue. """
        return self.ctxt.new_array_access(self.data_cells,
                                          self.idx,
                                          loc)


    def current_data_is_zero(self, loc):
        """Get 'data_cells[idx] == 0' as a boolean rvalue."""
        return self.ctxt.new_comparison(gccjit.Comparison.EQ,
                                        self.get_current_data(loc),
                                        self.byte_zero,
                                        loc)

    def compile_char(self, ch):
        """Compile one bf character."""
        loc = self.ctxt.new_location(self.filename,
                                     self.line,
                                     self.column)

        # Turn this on to trace execution, by injecting putchar()
        # of each source char.
        if 0:
            arg = self.ctxt.new_rvalue_from_int (self.int_type,
                                                 ch)
            call = self.ctxt.new_call (self.func_putchar,
                                       [arg],
                                       loc)
            self.curblock.add_eval (call, loc)

        if ch == '>':
            self.curblock.add_comment(b"'>': idx += 1;", loc)
            self.curblock.add_assignment_op(self.idx,
                                            gccjit.BinaryOp.PLUS,
                                            self.int_one,
                                            loc)
        elif ch == '<':
            self.curblock.add_comment(b"'<': idx -= 1;", loc)
            self.curblock.add_assignment_op(self.idx,
                                            gccjit.BinaryOp.MINUS,
                                            self.int_one,
                                            loc)
        elif ch == '+':
            self.curblock.add_comment(b"'+': data[idx] += 1;", loc)
            self.curblock.add_assignment_op(self.get_current_data (loc),
                                            gccjit.BinaryOp.PLUS,
                                            self.byte_one,
                                            loc)
        elif ch == '-':
            self.curblock.add_comment(b"'-': data[idx] -= 1;", loc)
            self.curblock.add_assignment_op(self.get_current_data(loc),
                                            gccjit.BinaryOp.MINUS,
                                            self.byte_one,
                                            loc)
        elif ch == '.':
            arg = self.ctxt.new_cast(self.get_current_data(loc),
                                     self.int_type,
                                     loc)
            call = self.ctxt.new_call(self.func_putchar,
                                      [arg],
                                      loc)
            self.curblock.add_comment(b"'.': putchar ((int)data[idx]);",
                                      loc)
            self.curblock.add_eval(call, loc)
        elif ch == ',':
            call = self.ctxt.new_call(self.func_getchar, [], loc)
            self.curblock.add_comment(b"',': data[idx] = (unsigned char)getchar ();",
                                      loc)
            self.curblock.add_assignment(self.get_current_data(loc),
                                         self.ctxt.new_cast(call,
                                                            self.byte_type,
                                                            loc),
                                         loc)
        elif ch == '[':
            loop_test = self.func.new_block()
            on_zero = self.func.new_block()
            on_non_zero = self.func.new_block()

            self.curblock.end_with_jump(loop_test, loc)

            loop_test.add_comment(b"'['", loc)
            loop_test.end_with_conditional(self.current_data_is_zero(loc),
                                           on_zero,
                                           on_non_zero,
                                           loc)
            self.open_parens.append(Paren(loop_test, on_non_zero, on_zero))
            self.curblock = on_non_zero;
        elif ch == ']':
            self.curblock.add_comment(b"']'", loc)
            if not self.open_parens:
                raise CompileError(self, "mismatching parens")
            paren = self.open_parens.pop()
            self.curblock.end_with_jump(paren.b_test)
            self.curblock = paren.b_after
        elif ch == '\n':
            self.line +=1;
            self.column = 0;

        if ch != '\n':
            self.column += 1


    def parse_into_ctxt(self, filename):
        """
        Parse the given .bf file into the gccjit.Context, containing a
        single "main" function suitable for compiling into an executable.
        """
        self.filename = filename;
        self.line = 1
        self.column = 0
        with open(filename) as f_in:
            for ch in f_in.read():
                self.compile_char(ch)
        self.curblock.end_with_void_return()

    # Compiling to an executable

    def compile_to_file(self, output_path):
        # Wrap "func" up in a "main" function
        mainfunc, argv, argv = gccjit.make_main(self.ctxt)
        block = mainfunc.new_block()
        block.add_eval(self.ctxt.new_call(self.func, []))
        block.end_with_return(self.int_zero)
        self.ctxt.compile_to_file(gccjit.OutputKind.EXECUTABLE,
                                  output_path)

    # Running the generated code in-process

    def run(self):
        import ctypes
        result = self.ctxt.compile()
        py_func_type = ctypes.CFUNCTYPE(None)
        py_func = py_func_type(result.get_code(b'func'))
        py_func()

# Entrypoint

def main(argv):
    from optparse import OptionParser
    parser = OptionParser()
    parser.add_option("-o", "--output", dest="outputfile",
                      help="compile to FILE", metavar="FILE")
    (options, args) = parser.parse_args()
    if len(args) != 1:
        raise ValueError('No input file')
    inputfile = args[0]
    c = Compiler()
    c.parse_into_ctxt(inputfile)
    if options.outputfile:
        c.compile_to_file(options.outputfile)
    else:
        c.run()

if __name__ == '__main__':
    try:
        main(sys.argv)
    except Exception as exc:
        print(exc)
        sys.exit(1)
