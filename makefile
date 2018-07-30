PREFIX ?= /usr
MANDIR ?= $(PREFIX)/share/man

all:
	@echo Run \'make install\' to install NAM.

install:
	@mkdir -p $(DESTDIR)$(PREFIX)/bin
	@cp -p NAM.sh $(DESTDIR)$(PREFIX)/bin/NAM
	@chmod 755 $(DESTDIR)$(PREFIX)/bin/NAM

uninstall:
	@rm -rf $(DESTDIR)$(PREFIX)/bin/NAM
