#!/bin/bash

# Make an environment file

# You should at least set up the following...
#   Your release
#   Your development area
#   Special cetbuildtools
#   gdb

# Usage: make_env.sh > build.env

# This will remove the dangerous elements.

TMPFILE=`mktemp`

printenv | sort | \
sed -e '/^HOME=/d' \
    -e '/^HOSTNAME=/d' \
    -e '/^LANG=/d' \
    -e '/^LS_COLORS=/d' \
    -e '/^OLDPWD=/d' \
    -e '/^PWD=/d' \
    -e '/^\_=/d' \
    -e '/^USER=/d' \
    -e '/^TERM=/d' > $TMPFILE

# Copy LD_LIBRARY_PATH to HOLD_LD_LIBRARY_PATH in case something clobbers LD_LIBRARY_PATH
sed -E 's%^LD_LIBRARY_PATH=(.*)%LD_LIBRARY_PATH=\1\'$'\n''HOLD_LD_LIBRARY_PATH=\1%' $TMPFILE

