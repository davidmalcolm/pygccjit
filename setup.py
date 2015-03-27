"""Python bindings for libgccjit"""

# Attempt using setuptools which supports the "tests" target.
try:
    from setuptools import setup
    from distutils.extension import Extension
except ImportError:
    from distutils.core import setup
    from distutils.extension import Extension

from Cython.Distutils import build_ext

doclines = __doc__.split("\n")

classifiers = """\
Development Status :: 3 - Alpha
Intended Audience :: Developers
License :: OSI Approved :: GNU General Public License v3 or later (GPLv3+)
Programming Language :: Python
Topic :: Software Development :: Libraries :: Python Modules
Operating System :: Unix
Programming Language :: Python :: 2
Programming Language :: Python :: 3
"""

setup(
    name='gccjit',
    version='0.4',
    author="David Malcolm",
    author_email="jit@gcc.gnu.org",
    url="https://github.com/davidmalcolm/pygccjit",
    packages=['gccjit',],
    license='GPL v3',
    description = doclines[0],
    classifiers = filter(None, classifiers.split("\n")),
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
