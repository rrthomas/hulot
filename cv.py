#!/usr/bin/python
# FIXME: Add support for auto-decompression

import sys
import argparse
import magic
import xdg.Mime  # FIXME: write type stubs for this.
import MIMEConvert

# Command-line arguments
parser = argparse.ArgumentParser(
    prog="cv",
    description="Convert files from one MIME type to another.",
    formatter_class=argparse.RawDescriptionHelpFormatter,
)
parser.add_argument(
    "-V",
    "--version",
    action="version",
    version="%(prog)s 0.1 (c) 2011 Reuben Thomas <rrt@sc3d.org>",
)
parser.add_argument("infile", metavar="IN-FILE")
parser.add_argument("outfile", metavar="OUT-FILE")
parser.add_argument("outtype", metavar="OUT-MIME-TYPE", nargs="?")

args = parser.parse_args()

intype = magic.from_file(args.infile)
if intype in ("binary", "application/octet-stream", "text/plain"):
    # Get a second opinion if type from libmagic is too general
    intype = xdg.Mime.get_type2(args.infile)
if not args.outtype:
    args.outtype = xdg.Mime.get_type(args.outfile)
# print(args.infile, intype, args.outfile, args.outtype)
# FIXME find suitable "die" function
with sys.stdout if args.outfile == "-" else open(args.outfile, "wb") as out:
    print(MIMEConvert.convert(args.infile, intype, args.outtype), file=out)
