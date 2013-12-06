MIRARI = ../main.native
TESTS  = kv_ro

MAINS  = $(patsubst %, %-main, $(TESTS))
RUNS   = $(patsubst %, %-run, $(TESTS))
CLEANS = $(patsubst %, %-clean, $(TESTS))

all: $(MAINS)
	@

run: $(RUNS)
	@

clean: $(CLEANS)
	@

%-main:
	$(MIRARI) configure $*/config.ml --no-opam
	$(MAKE) -C $*

%-run:
	$(MIRARI) run $*/config.ml

%-clean:
	$(MIRARI) clean $*/config.ml --no-opam
