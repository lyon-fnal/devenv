#!/bin/bash

# Make an environment file

# You should at least set up the following...
#   Your release
#   Your development area
#   Special cetbuildtools
#   gdb

# Usage: make_env.sh > build.env

# This will remove the dangerous elements.

printenv | sort | \
sed -e '/^HOME=/d' \
    -e '/^HOSTNAME=/d' \
    -e '/^LANG=/d' \
    -e '/^LS_COLORS=/d' \
    -e '/^OLDPWD=/d' \
    -e '/^PWD=/d' \
    -e '/^\_=/d' \
    -e '/^USER=/d' \
    -e '/^TERM=/d'