PROGNM  ?= ssrt
PREFIX  ?= /usr
BINDIR  ?= $(PREFIX)/bin
SHRDIR  ?= $(PREFIX)/share
MANDIR  ?= $(SHRDIR)/man/man1

MANPAGE  = $(PROGNM).1

.PHONY: install
install: $(PROGNM).out

	install -Dm755 $(PROGNM)  -t $(DESTDIR)$(BINDIR)
	install -Dm644 $(MANPAGE) -t $(DESTDIR)$(MANDIR)
	install -Dm644 LICENSE    -t $(DESTDIR)$(SHRDIR)/licenses/$(PROGNM)

.PHONY: uninstall
uninstall:
	rm $(DESTDIR)$(BINDIR)/$(PROGNM)
	rm -rf $(DESTDIR)$(ASSETDIR)
	rm $(DESTDIR)$(MANDIR)/$(MANPAGE)
	rm -rf $(DESTDIR)$(SHRDIR)/licenses/$(PROGNM)
