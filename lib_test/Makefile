MIRAGE = ../main.native
TESTS  = console kv_ro fat net ip http combinator basic_ethif basic_stackv4 basic_http
# MODE ?= -t xen
MODE ?= -t unix
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
	$(MIRAGE) configure -f $*/config.ml $(BFLAGS) $(MODE)

%-build: %-configure
	$(MIRAGE) build -f $*/config.ml

%-run: %-build
	$(MIRAGE) run -f $*/config.ml

%-clean:
	rm -f $*/mir-main
	$(MIRAGE) clean -f $*/config.ml $(BFLAGS) || true
