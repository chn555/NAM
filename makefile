PREFIX ?= /usr
MANDIR ?= $(PREFIX)/share/man

all:
	@echo Run \'make install\' to install NAMA.

install:
	@mkdir -p $(DESTDIR)$(PREFIX)/bin/
	@cp -p nama $(DESTDIR)$(PREFIX)/bin/
	@chmod 755 $(DESTDIR)$(PREFIX)/bin/nama

uninstall:
	@rm -rf $(DESTDIR)$(PREFIX)/bin/nama
