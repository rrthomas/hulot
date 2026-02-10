# (c) 2002-2023 Reuben Thomas (rrt@sc3d.org, https://github.com/rrthomas/hulot)
# Distributed under the GNU General Public License version 3, or (at
# your option) any later version.

import re
import sys

from . import main


sys.argv[0] = re.sub(r"__main__.py$", "hulot", sys.argv[0])
main()
