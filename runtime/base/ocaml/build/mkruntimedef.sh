#!/bin/sh
# $Id: mkruntimedef.sh 8416 2007-10-08 14:19:34Z doligez $
echo 'let builtin_exceptions = [|'; \
sed -n -e 's|.*/\* \("[A-Za-z_]*"\) \*/$|  \1;|p' byterun/fail.h | \
sed -e '$s/;$//'; \
echo '|]'; \
echo 'let builtin_primitives = [|'; \
sed -e 's/.*/  "&";/' -e '$s/;$//' byterun/primitives; \
echo '|]'
