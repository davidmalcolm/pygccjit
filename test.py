import gccjit

def cb(ctxt):
    """
    Create this function:
      int square(int i)
      {
         return i * i;
      }
    """
    param_i = ctxt.new_param(None,
                             ctxt.get_int_type(),
                             b'i')
    fn = ctxt.new_function(None,
                           gccjit.FUNCTION_EXPORTED,
                           ctxt.get_int_type(),
                           b"square",
                           [param_i])
    fn.add_return(None,
                  ctxt.new_binary_op(None,
                                     gccjit.BINARY_OP_MULT,
                                     ctxt.get_int_type(),
                                     param_i, param_i))

for i in range(5):
    ctxt = gccjit.Context(cb)
    if 0:
        ctxt.set_bool_option(gccjit.BOOL_OPTION_DUMP_INITIAL_TREE, True)
        ctxt.set_bool_option(gccjit.BOOL_OPTION_DUMP_INITIAL_GIMPLE, True)
    if 0:
        ctxt.set_int_option(gccjit.INT_OPTION_OPTIMIZATION_LEVEL, 0)
    result = ctxt.compile()
    code = result.get_code(b"square")
    print('code(5) = %s' % code(5))
