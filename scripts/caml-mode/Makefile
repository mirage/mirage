FILES=caml-types.el
EMACSDIR=
EMACS=emacs

COMPILECMD=\
	(progn \
	  (setq load-path (cons "." load-path)) \
	  (byte-compile-file "caml-types.el"))

nstall:
	@if test "$(EMACSDIR)" = ""; then \
	  set xxx `($(EMACS) --batch --eval "(mapcar 'print load-path)") \
	           2>/dev/null | \
	           sed -n -e '/\/site-lisp/s/"//gp'`; \
	  if test "$$2" = ""; then \
	    echo "Cannot determine Emacs site-lisp directory"; \
	    exit 2; \
	  fi; \
	  $(MAKE) EMACSDIR="$$2" simple-install; \
	else \
	  $(MAKE) simple-install; \
	fi

# install the .el files, but do not compile them.
install-el:
	$(MAKE) NOCOMPILE=true install

simple-install:
	@echo "Installing in $(EMACSDIR)..."
	if test -d $(EMACSDIR); then : ; else mkdir -p $(EMACSDIR); fi
	cp $(FILES) $(EMACSDIR)
	if [ -z "$(NOCOMPILE)" ]; then \
	  cd $(EMACSDIR); $(EMACS) --batch --eval '$(COMPILECMD)'; \
	fi
