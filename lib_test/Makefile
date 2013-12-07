MIRARI = ../main.native
TESTS  = console kv_ro fat

CONFIGS = $(patsubst %, %-configure, $(TESTS))
RUNS    = $(patsubst %, %-run, $(TESTS))
CLEANS  = $(patsubst %, %-clean, $(TESTS))

all: $(CONFIGS)
	@

run: $(RUNS)
	@

clean: $(CLEANS)
	@

%-configure:
	$(MIRARI) configure $*/config.ml --no-opam
	$(MAKE) -C $*

%-run:
	$(MIRARI) run $*/config.ml

%-clean:
	$(MIRARI) clean $*/config.ml --no-opam
