MIRAGE = ../main.native
TESTS  = console kv_ro fat net ip http combinator basic_ethif basic_stackv4 basic_http
# MODE ?= xen
MODE   ?= unix
MFLAGS ?=

CONFIGS = $(patsubst %, %-configure, $(TESTS))
BUILDS  = $(patsubst %, %-build, $(TESTS))
RUNS    = $(patsubst %, %-run, $(TESTS))
CLEANS  = $(patsubst %, %-clean, $(TESTS))

all: $(CONFIGS)
run: $(RUNS)
build: $(BUILDS)
clean: $(CLEANS)

%-configure:
	$(MIRAGE) configure $*/config.ml $(MFLAGS) --$(MODE)

%-build: %-configure
	$(MIRAGE) build $*/config.ml

%-run: %-build
	$(MIRAGE) run $*/config.ml

%-clean:
	rm -f $*/mir-main
	$(MIRAGE) clean $*/config.ml $(MFLAGS) || true
