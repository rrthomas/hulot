#!/usr/bin/python
# FIXME: Add support for auto-decompression

import sys
import argparse
import magic
import xdg.Mime
import MIMEConvert

# Command-line arguments
parser = argparse.ArgumentParser(prog='cv',
                                 description='Convert files from one MIME type to another.',
                                 formatter_class=argparse.RawDescriptionHelpFormatter)
parser.add_argument('-V', '--version', action='version',
                    version='%(prog)s 0.1 (c) 2011 Reuben Thomas <rrt@sc3d.org>')
parser.add_argument('infile', metavar='IN-FILE')
parser.add_argument('outfile', metavar='OUT-FILE')
parser.add_argument('outtype', metavar='OUT-MIME-TYPE', nargs='?')

args = parser.parse_args()

ms = magic.open(magic.NONE)
ms.load()
ms.setflags(magic.MIME_TYPE)
intype = ms.file(args.infile)
if intype == "application/octet-stream":
    intype = xdg.Mime.get_type(infile) 
if not args.outtype:
    args.outtype = xdg.Mime.get_type(args.outfile)
print args.infile, intype, args.outfile, args.outtype
# FIXME find suitable "die" function
out = sys.stdout if args.outfile == "-" else open(args.outfile, 'w')
print >>out, MIMEConvert.convert(rags.infile, intype, outtype)
