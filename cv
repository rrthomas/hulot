#!/usr/bin/env python3
#
# © Reuben Thomas <rrt@sc3d.org> 2023
# Released under the GPL version 3, or (at your option) any later version.
# FIXME: Add support for auto-decompression

from __future__ import annotations

import sys
import argparse
import warnings
from warnings import warn
from typing import (
    Optional, Union, Type, NoReturn, TextIO,
)

import magic
import xdg.Mime  # FIXME: write type stubs for this.
from mime_convert import convert

# Command-line arguments
parser = argparse.ArgumentParser(
    description="Convert files from one MIME type to another.",
    formatter_class=argparse.RawDescriptionHelpFormatter,
)
parser.add_argument(
    "-V",
    "--version",
    action="version",
    version="%(prog)s 0.1 (c) 2023 Reuben Thomas <rrt@sc3d.org>",
)
parser.add_argument("infile", metavar="IN-FILE")
parser.add_argument("outfile", metavar="OUT-FILE")
parser.add_argument("outtype", metavar="OUT-MIME-TYPE", nargs="?")
parser.add_argument("intype", metavar="IN-MIME-TYPE", nargs="?")
args = parser.parse_args()


# Error messages
def simple_warning( # pylint: disable=too-many-arguments
        message: Union[Warning, str],
        category: Type[Warning], # pylint: disable=unused-argument
        filename: str, # pylint: disable=unused-argument
        lineno: int, # pylint: disable=unused-argument
        file: Optional[TextIO] = sys.stderr, # pylint: disable=redefined-outer-name
        line: Optional[str] = None # pylint: disable=unused-argument
) -> None:
    print(f'{parser.prog}: {message}', file=file or sys.stderr)
warnings.showwarning = simple_warning

def die(code: int, msg: str) -> NoReturn:
    warn(msg)
    sys.exit(code)


if args.intype is not None:
    intype = args.intype
else:
    intype = magic.from_file(args.infile)
    if intype in ("binary", "application/octet-stream", "text/plain"):
        # Get a second opinion if type from libmagic is too general
        intype = xdg.Mime.get_type2(args.infile)
if not args.outtype:
    args.outtype = xdg.Mime.get_type2(args.outfile)
# print(args.infile, intype, args.outfile, args.outtype)
try:
    with sys.stdout.buffer if args.outfile == "-" else open(args.outfile, "wb") as out:
        out.write(convert(args.infile, intype, args.outtype))
except Exception as e:
    die(1, str(e))
