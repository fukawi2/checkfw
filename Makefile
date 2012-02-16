### The project name
PROJECT=checkfw

### Dependencies
DEP_BINS=cat iptables ip6tables grep

### Destination Paths
D_BIN=/usr/local/sbin
D_DOC=/usr/local/share/doc/$(PROJECT)
D_MAN=/usr/local/share/man

### Lists of files to be installed
F_DOCS=README doc/LICENSE
F_MAN=man/*

###############################################################################

all: install

install: test bin docs
	# install the actual scripts
	install -D -m 0755 src/$(PROJECT).sh $(DESTDIR)$(D_BIN)/$(PROJECT)
	# install documentation
	for f in $(F_DOCS) ; do \
		install -D -m 0644 $$f $(DESTDIR)$(D_DOC)/$$f || exit 1 ; \
	done

test:
	@echo "==> Checking for required external dependencies"
	for bindep in $(DEP_BINS) ; do \
		which $$bindep > /dev/null || { echo "$$bindep not found"; exit 1;} ; \
	done

	@echo "==> Checking for valid script syntax"
	@bash -n src/$(PROJECT).sh

	@echo "==> Do a little dance; It's good!"

bin: test src/$(PROJECT).sh

docs: $(F_DOCS)

uninstall:
	rm -f $(DESTDIR)$(D_BIN)/$(PROJECT)
	rm -f $(DESTDIR)$(D_DOC)/*
	rmdir $(DESTDIR)$(D_DOC)/
