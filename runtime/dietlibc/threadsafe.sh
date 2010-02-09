#!/bin/sh
(gcc -E - << EOF | grep WANT_THREAD_SAFE > /dev/null) || echo libpthread/pthread_*.c
#include "dietfeatures.h"
WANT_THREAD_SAFE
EOF
