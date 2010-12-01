PREFIX ?= $(HOME)/mir-inst
export PREFIX

tools:
	@cd mpl && $(MAKE) && $(MAKE) install
	@cd crunch && $(MAKE) && $(MAKE) install
	@cd mir && $(MAKE) install

.PHONY: clean
clean:
	@cd mpl && $(MAKE) clean
	@cd crunch && $(MAKE) clean
	@cd mir && $(MAKE) clean
