MIRARI = ../main.native
TESTS  = console kv_ro fat net ip http combinator basic_ethif basic_stackv4
# MODE ?= xen
MODE ?= unix
BFLAGS ?= --no-opam

CONFIGS = $(patsubst %, %-configure, $(TESTS))
BUILDS  = $(patsubst %, %-build, $(TESTS))
RUNS    = $(patsubst %, %-run, $(TESTS))
CLEANS  = $(patsubst %, %-clean, $(TESTS))

all: $(CONFIGS)
run: $(RUNS)
build: $(BUILDS)
clean: $(CLEANS)

%-configure:
	$(MIRARI) configure $*/config.ml $(BFLAGS) --$(MODE)

%-build: %-configure
	$(MIRARI) build $*/config.ml

%-run: %-build
	$(MIRARI) run $*/config.ml

%-clean:
	rm -f $*/mir-main
	$(MIRARI) clean $*/config.ml $(BFLAGS) || true
