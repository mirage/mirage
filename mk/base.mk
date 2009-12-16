debug ?= n
CC ?= gcc

OS = $(shell uname -s | tr '[A-Z]' '[a-z]' | sed -e 's/darwin/macosx/g')
ifeq ($(debug),y)
DEBUG_CFLAGS = -O1 -fno-omit-frame-pointer
else
DEBUG_CFLAGS = -O3 -fomit-frame-pointer
endif
