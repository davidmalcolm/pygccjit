# Attempt using setuptools which supports the "tests" target.
try:
    from setuptools import setup
    from distutils.extension import Extension
except ImportError:
    from distutils.core import setup
    from distutils.extension import Extension

from Cython.Distutils import build_ext

setup(
    name='gccjit',
    version='0.1',
    packages=['gccjit',],
    license='GPL v3',
    long_description='gccjit',
    cmdclass = {'build_ext': build_ext},
    ext_modules = [Extension("gccjit._gccjit", ["gccjit/gccjit.pyx"],
                             libraries=["gccjit"],
                             # Hacks for ease of hacking on this:
                             #include_dirs = ['/home/david/coding/gcc-python/gcc-git-jit-clean/src/gcc/jit'],
                             #library_dirs=["/home/david/coding/gcc-python/gcc-git-jit-clean/build/gcc/"],
                             )],
    test_suite='tests',
    test_loader='tests:TestLoader',
)
