#!/usr/bin/env python3
import os
import sys
import ast
try:
    from setuptools import setup
    HAVE_SETUPTOOLS = True
except ImportError:
    from distutils.core import setup
    HAVE_SETUPTOOLS = False


def find_version(filename):
    with open(filename) as f:
        initlines = f.readlines()
    version_line = None
    for line in initlines:
        if line.startswith('__version__'):
            vstr = line.strip().split()[-1]
            ver = ast.literal_eval(vstr)
            break
    return ver


def main():
    """The main entry point."""
    if sys.version_info[:2] < (3, 4):
        sys.exit('xonsh currently requires Python 3.4+')
    with open(os.path.join(os.path.dirname(__file__), 'README.rst'), 'r') as f:
        readme = f.read()
    scripts = ['scripts/rever']
    skw = dict(
        name='rever',
        description='Release Versions of Software',
        long_description=readme,
        license='BSD',
        version=find_version('rever/__init__.py'),
        author='Anthony Scopatz',
        maintainer='Anthony Scopatz',
        author_email='scopatz@gmail.com',
        url='https://github.com/scopatz/rever',
        platforms='Cross Platform',
        classifiers=['Programming Language :: Python :: 3'],
        packages=['rever'],
        package_dir={'rever': 'rever'},
        package_data={'rever': ['*.xsh']},
        scripts=scripts,
        zip_safe=False,
        )
    # WARNING!!! Do not use setuptools 'console_scripts'
    # It validates the depenendcies (of which we have none) everytime the
    # 'rever' command is run. This validation adds ~0.2 sec. to the startup
    # time of xonsh - for every single xonsh run.  This prevents us from
    # reaching the goal of a startup time of < 0.1 sec.  So never ever write
    # the following:
    #
    #     'console_scripts': ['rever = rever.main:main'],
    #
    # END WARNING
    setup(**skw)


if __name__ == '__main__':
    main()