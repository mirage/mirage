MIRARI = ../main.native
TESTS  = kv_ro

MAINS  = $(patsubst %, %/main.ml, $(TESTS))

all: $(MAINS)
	echo $(MAINS)
	@

%/main.ml:
	$(MIRARI) configure $*/config.ml --no-install
	$(MAKE) -D $*

clean:
	$(MIRARI) clean $*/config.ml
