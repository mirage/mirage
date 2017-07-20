.PHONY: all clean doc

all:
	jbuilder build --dev

clean:
	jbuilder clean

doc:
	jbuilder build --dev @doc

REPO=../opam-repository
PACKAGES=$(REPO)/packages

# until we have https://github.com/ocaml/opam-publish/issues/38
pkg-%:
	topkg opam pkg -n $*
	mkdir -p $(PACKAGES)/$*
	cp -r _build/$*.* $(PACKAGES)/$*/
	rm -f $(PACKAGES)/$*/$*.opam
	cd $(PACKAGES) && git add $*

PKGS=$(basename $(wildcard *.opam))
opam-pkg:
	$(MAKE) $(PKGS:%=pkg-%)
