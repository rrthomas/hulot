# MimeConvert
# Convert one MIME type into another
# (c) 2002-2023 Reuben Thomas (rrt@sc3d.org, https://github.com/rrthomas/Hulot)
# Distributed under the GNU General Public License version 3, or (at
# your option) any later version.

# FIXME: Implement chained converters using transitive closure

# FIXME: Implement many-to-many converters using convert and pacpl.

# FIXME: Add support for auto-decompression to CLI invocation.

# TODO: Can also think about systematic transformations such as cropping and
# scaling pictures, or downsampling sound. Should be provided by different
# programs, one for each of a limited set of canonical types, which can be
# converted to from any other type of the same sort.

from __future__ import annotations

import importlib.metadata
import os
import sys
import argparse
import warnings
import re
import subprocess
from pathlib import Path
from warnings import warn
from typing import (
    Optional, List, Union, Type, NoReturn, TextIO,
)

import magic
import xdg.Mime  # FIXME: write type stubs for this.

VERSION = importlib.metadata.version("hulot")

# Error messages
prog: str

def simple_warning( # pylint: disable=too-many-arguments
    message: Union[Warning, str],
    category: Type[Warning], # pylint: disable=unused-argument
    filename: str, # pylint: disable=unused-argument
    lineno: int, # pylint: disable=unused-argument
    file: Optional[TextIO] = sys.stderr, # pylint: disable=redefined-outer-name
    line: Optional[str] = None # pylint: disable=unused-argument
) -> None:
    print(f'{prog}: {message}', file=file or sys.stderr)

warnings.showwarning = simple_warning

def die(code: int, msg: str) -> NoReturn:
    warn(Warning(msg))
    sys.exit(code)


converters_dir = os.path.join(os.path.dirname(os.path.abspath(__file__)), "converters")
Converters = set(os.listdir(converters_dir))

# FIXME: Should have a rule for this
# "text/plain>text/html" => ,

# Treat empty files as text
# FIXME: generalize application/x-empty>text/html to application/x-empty>*

# FIXME: Reuse (and expand) the list of programming languages used with
# highlight and for identity transformations to text/plain.


def mimetypes_to_converter(srctype, desttype):
    srctype_file = re.sub(r"/", "_", srctype)
    desttype_file = re.sub(r"/", "_", desttype)
    return f"{srctype_file}→{desttype_file}"


def converter_to_mimetypes(converter):
    m = re.match(r"(.*)→(.*)", converter)
    if not m:
        raise ValueError(f"bad converter {converter}")
    srctype = re.sub(r"_", "/", m[1])
    desttype = re.sub(r"_", "/", m[2])
    return srctype, desttype


# FIXME: Detect and return errors, so that e.g. DarkGlass can give a generic
# error instead of leaking permissions information
def convert(
    file, srctype="application/octet-stream", desttype="application/octet-stream"
):
    if file != "-" and not os.path.exists(file):
        raise IOError("file not found")
    path = Path(file)
    filebase, fileext = path.stem, path.suffix
    # print(f"{file} {srctype} {desttype}", file=sys.stderr)
    if srctype == desttype:
        return open(file, mode="rb").read()
    converter = mimetypes_to_converter(srctype, desttype)
    if not converter in Converters:
        raise IOError(f"no converter {converter} found")
    return subprocess.check_output(
        [
            os.path.join(converters_dir, converter),
            file,
            srctype,
            desttype,
            fileext,
            filebase,
        ]
    )


def converters(match_pat=r".*"):
    convs = []
    for conv in Converters:
        if re.search(match_pat, conv):
            try:
                srctype, desttype = converter_to_mimetypes(conv)
                convs.append(f"{srctype}→{desttype}")
            except:
                pass
    return convs



# CLI main entry point
def main(  # pylint: disable=dangerous-default-value
    argv: List[str] = sys.argv[1:],
) -> None:
    # Command-line arguments
    parser = argparse.ArgumentParser(
        description="Convert files from one MIME type to another.",
        formatter_class=argparse.RawDescriptionHelpFormatter,
    )
    global prog
    prog = parser.prog
    parser.add_argument(
        "-V",
        "--version",
        action="version",
        version="%(prog)s " + VERSION + " (c) 2023 Reuben Thomas <rrt@sc3d.org>",
    )
    parser.add_argument("infile", metavar="IN-FILE")
    parser.add_argument("outfile", metavar="OUT-FILE")
    parser.add_argument("outtype", metavar="OUT-MIME-TYPE", nargs="?")
    parser.add_argument("intype", metavar="IN-MIME-TYPE", nargs="?")
    args = parser.parse_args(argv)

    if args.intype is not None:
        intype = args.intype
    else:
        intype = magic.detect_from_filename(args.infile).mime_type
        if intype in ("binary", "application/octet-stream", "text/plain"):
            # Get a second opinion if type from libmagic is too general
            intype = str(xdg.Mime.get_type2(args.infile))
    if not args.outtype:
        args.outtype = str(xdg.Mime.get_type2(args.outfile))
    # print(args.infile, intype, args.outfile, args.outtype)
    try:
        with sys.stdout.buffer if args.outfile == "-" else open(args.outfile, "wb") as out:
            out.write(convert(args.infile, intype, args.outtype))
    except Exception as e:
        die(1, str(e))


# CLI hulot-converters entry point
def mime_converters(  # pylint: disable=dangerous-default-value
    argv: List[str] = sys.argv[1:],
) -> None:
    # Command-line arguments
    parser = argparse.ArgumentParser(
        description="List MIME converters.",
        formatter_class=argparse.RawDescriptionHelpFormatter,
    )
    global prog
    prog = parser.prog
    parser.add_argument(
        "-V",
        "--version",
        action="version",
        version="%(prog)s " + VERSION + " (c) 2023 Reuben Thomas <rrt@sc3d.org>",
    )
    parser.add_argument("--match", metavar="REGEX", help="regex to match against")
    args = parser.parse_args(argv)

    if args.match is None:
        match = ".*"
    else:
        match = args.match
    print("\n".join(converters(match)))
