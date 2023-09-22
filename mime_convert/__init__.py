# MimeConvert
# Convert one MIME type into another
# (c) 2002-2023 Reuben Thomas (rrt@sc3d.org, https://github.com/rrthomas/Hulot)
# Distributed under the GNU General Public License version 3, or (at
# your option) any later version.

# FIXME: Implement chained converters using transitive closure

# FIXME: Implement many-to-many converters using convert and pacpl.

# TODO: Can also think about systematic transformations such as cropping and
# scaling pictures, or downsampling sound. Should be provided by different
# programs, one for each of a limited set of canonical types, which can be
# converted to from any other type of the same sort.

import os
import re
import subprocess
from pathlib import Path

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
