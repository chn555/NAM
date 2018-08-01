PREFIX ?= /usr
MANDIR ?= $(PREFIX)/share/man

all:
	@echo Run \'make install\' to install NAMA.

install:
	@mkdir -p $(DESTDIR)$(PREFIX)/bin/
	@mkdir -p $(DESTDIR)$(MANDIR)/man1
	@cp -p nama $(DESTDIR)$(PREFIX)/bin/
	@cp -p nama.1 $(DESTDIR)$(MANDIR)/man1
	@chmod 755 $(DESTDIR)$(PREFIX)/bin/nama

uninstall:
	@rm -rf $(DESTDIR)$(PREFIX)/bin/nama
	@rm -rf $(DESTDIR)$(MANDIR)/man1/nama.1*
