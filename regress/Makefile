.PHONY: clean all

JOBS ?= -j 5
MB=mir-build $(JOBS)

all:
	$(MB) basic.run
	$(MB) lwt.run
	$(MB) block.run

clean:
	$(MB) -clean
