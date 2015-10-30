# OASIS_START
# DO NOT EDIT (digest: a3c674b4239234cbbe53afe090018954)

SETUP = ocaml setup.ml

build: setup.data
	$(SETUP) -build $(BUILDFLAGS)

doc: setup.data build
	$(SETUP) -doc $(DOCFLAGS)

test: setup.data build
	$(SETUP) -test $(TESTFLAGS)

all:
	$(SETUP) -all $(ALLFLAGS)

install: setup.data
	$(SETUP) -install $(INSTALLFLAGS)

uninstall: setup.data
	$(SETUP) -uninstall $(UNINSTALLFLAGS)

reinstall: setup.data
	$(SETUP) -reinstall $(REINSTALLFLAGS)

clean:
	$(SETUP) -clean $(CLEANFLAGS)

distclean:
	$(SETUP) -distclean $(DISTCLEANFLAGS)

setup.data:
	$(SETUP) -configure $(CONFIGUREFLAGS)

configure:
	$(SETUP) -configure $(CONFIGUREFLAGS)

.PHONY: build doc test all install uninstall reinstall clean distclean configure

# OASIS_STOP


NAME    = $(shell grep 'Name:' _oasis    | sed 's/Name: *//')
VERSION = $(shell grep 'Version:' _oasis | sed 's/Version: *//')

ARCHIVE = https://github.com/mirage/$(NAME)/archive/$(VERSION).tar.gz

# doc update

doc/html/.git:
	mkdir -p doc/html
	cd doc/html && (\
		git init && \
		git remote add origin git@github.com:mirage/$(NAME).git && \
		git checkout -b gh-pages \
	)

gh-pages: doc/html/.git
	cd doc/html && git checkout gh-pages
	rm -f doc/html/*.html
	cp $(NAME).docdir/*.html doc/html/
	cd doc/html && git add *.html
	cd doc/html && git commit -a -m "Doc updates"
	cd doc/html && git push origin gh-pages

# release

release:
	git tag -a $(VERSION) -m "Version $(VERSION)."
	git push upstream $(VERSION)
	$(MAKE) pr
