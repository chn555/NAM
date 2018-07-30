PREFIX ?= /usr
MANDIR ?= $(PREFIX)/share/man

all:
	@echo Run \'make install\' to install NAMA.

install:
	@mkdir -p $(DESTDIR)$(PREFIX)/nama
	@cp -p nama.sh $(DESTDIR)$(PREFIX)/bin/nama
	@chmod 755 $(DESTDIR)$(PREFIX)/bin/nama

uninstall:
	@rm -rf $(DESTDIR)$(PREFIX)/bin/nama