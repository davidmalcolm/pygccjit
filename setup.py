from distutils.core import setup
from distutils.extension import Extension
from Cython.Distutils import build_ext

setup(
    cmdclass = {'build_ext': build_ext},
    ext_modules = [Extension("gccjit", ["gccjit.pyx"],

                             # FIXME:
                             include_dirs = ['/home/david/coding/gcc-python/gcc-git-various-branches/src/gcc/jit'],
                             #FIXME:
                             library_dirs=["/home/david/coding/gcc-python/gcc-git-various-branches/build/gcc/"],
                             libraries=["gccjit"])]
)
