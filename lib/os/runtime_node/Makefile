FILES=console activations clock time main istring js
STUBS=dummy_stubs.c

.PHONY: stubs clean

stubs: $(FILES:%=../node/%.ml)
	(echo "#include <stdlib.h>"; \
	 echo "#include <stdio.h>"; \
	 echo "#define D(f) void f () { fprintf(stderr, \"Unimplemented Javascript primitive %s!\\\\n\", #f); exit(1); }"; \
	(sed -n -e 's/.*external[^"]*"\([^"%]*\)".*/D(\1)/p' $^ | \
	 sort | uniq)) \
	> $(STUBS)

clean:
	rm -f $(STUBS)
