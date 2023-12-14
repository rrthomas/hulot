# Hulot

Web site: https://github.com/rrthomas/Hulot  
Maintainer: Reuben Thomas <rrt@sc3d.org>  

Hulot is a simple command and framework for file conversion. It can guess
the MIME type of the input file from its name or contents and the output
MIME type from the output file name, or both MIME types can be given
explicitly. Another command allows the available converters to be listed and
filtered.

The functionality of Hulot is also available as a Python module.

Hulot is free software, licensed under the GNU GPL version 3 (or, at your
option, any later version).

Please send questions, comments, and bug reports to the maintainer, or
report them on the project’s web page (see above for addresses).


## Installation

Hulot is published on PyPI. Install it with `pip`:

`pip install hulot`

Most of the converters have dependencies. Unfortunately for now you have to
examine their source code to see what they are; soon they will be
documented.


## Invocation

```
hulot [-h] [-V] IN-FILE OUT-FILE [OUT-MIME-TYPE] [IN-MIME-TYPE]
```


## Development

Check out the git repository with:

```
git clone https://github.com/rrthomas/Hulot
```
