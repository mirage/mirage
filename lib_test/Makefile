MIRARI = ../main.native
TESTS  = kv_ro

MAINS  = $(patsubst %, %-main, $(TESTS))
CLEANS = $(patsubst %, %-clean, $(TESTS))

all: $(MAINS)
	@

clean: $(CLEANS)
	@

%-main:
	$(MIRARI) configure $*/config.ml --no-opam
	$(MAKE) -C $*

%-clean:
	$(MIRARI) clean $*/config.ml --no-opam
