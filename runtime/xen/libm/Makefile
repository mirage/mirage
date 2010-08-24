ROOTDIR=../..
include $(ROOTDIR)/mk/xen.mk

OBJDIR ?= ./obj

SSRC=$(wildcard *.S)
CSRC=$(wildcard *.c)

.PHONY: all
all: $(OBJDIR)/libm.a
	@ :

$(OBJDIR)/libm.a: $(SSRC:%.S=$(OBJDIR)/%.o) $(CSRC:%.c=$(OBJDIR)/%.o)
	rm -f $@
	ar rc $@ $^

$(OBJDIR)/.stamp:
	mkdir -p $(OBJDIR)
	@touch $@

CC = gcc
CFLAGS += -I./include

$(OBJDIR)/%.o: %.S $(OBJDIR)/.stamp
	$(CC) $(CFLAGS) -c -o $@ $<

$(OBJDIR)/%.o: %.c $(OBJDIR)/.stamp
	$(CC) $(CFLAGS) -c -o $@ $<

.PHONY: clean
clean:
	rm -rf $(OBJDIR)
