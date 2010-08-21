#!/bin/sh
# $Id: mkruntimedef.sh 10443 2010-05-20 09:44:25Z doligez $
echo 'let builtin_exceptions = [|'; \
sed -n -e 's|.*/\* \("[A-Za-z_]*"\) \*/$|  \1;|p' byterun/fail.h | \
sed -e '$s/;$//'; \
echo '|]'; \
echo 'let builtin_primitives = [|'; \
sed -e 's/.*/  "&";/' -e '$s/;$//' byterun/primitives; \
echo '|]'
