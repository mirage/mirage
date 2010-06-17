#!/bin/sh
# $Id: mkconfig.sh 8477 2007-11-06 15:16:56Z frisch $

cd `dirname $0`/..

sed -e 's/^\(.*\$([0-9]).*\)$/# \1/' \
    -e 's/\$(\([^)]*\))/${\1}/g' \
    -e 's/^FLEX.*$//g' \
    -e 's/^\([^#=]*\)=\([^"]*\)$/if [ "x$\1" = "x" ]; then \1="\2"; fi/' \
    config/Makefile > config/config.sh


