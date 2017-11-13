"""Some special rever tools"""
import os
import re
import sys
import hashlib
import urllib.request
from contextlib import contextmanager

from xonsh.tools import expand_path, print_color

def eval_version(v):
    """Evalauates the argument either as a template string which contains
    $VERSION (or other environment variables) or a callable which
    takes a single argument (that is $VERSION) and returns a string.
    """
    if callable(v):
        rtn = v($VERSION)
    else:
        rtn = expand_path(v)
    return rtn


def replace_in_file(pattern, new, fname):
    """Replaces a given pattern in a file"""
    with open(fname, 'r') as f:
        raw = f.read()
    lines = raw.splitlines()
    ptn = re.compile(pattern)
    for i, line in enumerate(lines):
        if ptn.match(line):
            lines[i] = new
    upd = '\n'.join(lines) + '\n'
    with open(fname, 'w') as f:
        f.write(upd)


@contextmanager
def indir(d):
    """Context manager for temporarily entering into a directory."""
    old_d = os.getcwd()
    ![cd @(d)]
    yield
    ![cd @(old_d)]


def render_authors(authors):
    """Parse a list of of tuples of authors into valid bibtex

    Parameters
    ----------
    authors: list of str
        The authors eg ['Your name in nicely formatted bibtex'].
        Please see ``<http://nwalsh.com/tex/texhelp/bibtx-23.html>`` for
        information about how to format your name for bibtex

    Returns
    -------
    str:
        Valid bibtex authors
    """
    if isinstance(authors, str):
        authors = (authors, )
    if len(authors) == 1:
        return ''.join(authors[0])
    else:
        return ' and '.join(authors)


def progress(count, total, prefix='', suffix='', width=60, file=None,
             fill='`·.,¸,.·*¯`·.,¸,.·*¯', color=None, empty=' '):
    """CLI progress bar"""
    # forked from https://gist.github.com/vladignatyev/06860ec2040cb497f0f3
    # under an MIT license, Copyright (c) 2016 Vladimir Ignatev
    file = sys.stdout if file is None else file
    filler = fill * (1 + width//len(fill))
    filled_len = int(round(width * count / float(total)))
    bar = filler[:filled_len] + empty * (width - filled_len)
    if color is None:
        color = 'YELLOW' if count < total else 'GREEN'
    frac = count / float(total)
    fmt = ('{prefix}[{{{color}}}{bar}{{NO_COLOR}}] '
           '{{{color}}}{frac:.1%}{{NO_COLOR}}{suffix}\r')
    s = fmt.format(prefix=prefix, color=color, bar=bar, frac=frac,
                   suffix=suffix)
    print_color(s, end='', file=file)
    file.flush()


def stream_url_progress(url, verb='downloading', chunksize=1024):
    """Generator yielding successive bytes from a URL.

    Parameters
    ----------
    url : str
        URL to open and stream
    verb : str
        Verb to prefix the url downloading with, default 'downloading'
    chunksize : int
        Number of bytes to return, defaults to 1 kb.

    Returns
    -------
    yields the bytes which is at most chunksize in length.
    """
    nbytes = 0
    print(verb + ' ' + url)
    with urllib.request.urlopen(url) as f:
        totalbytes = f.length
        while True:
            b = f.read(chunksize)
            lenbytes = len(b)
            nbytes += lenbytes
            if lenbytes == 0:
                break
            else:
                progress(nbytes, totalbytes or nbytes * 2)
                yield b
    if nbytes < totalbytes:
        color = 'RED'
        suffix = '{RED} FAILED{{NO_COLOR}\n'
    else:
        color = 'GREEN'
        suffix = '{GREEN} SUCCESS{NO_COLOR}\n'
    progress(nbytes, totalbytes, color=color, suffix=suffix)


def hash_url(url, hash='sha256'):
    """Hashes a URL, with a progress bar, and returns the hex representation"""
    hasher = getattr(hashlib, hash)()
    for b in stream_url_progress(url, verb='Hashing'):
        hasher.update(b)
    return hasher.hexdigest()
