PLATFORM := $(shell uname -s)

MKPDF_VERSION = 0.0.5
MKPDF_DIR = mkpdf-$(MKPDF_VERSION)-$(PLATFORM)
MKPDF_ARCHIVE = $(MKPDF_DIR).zip

laskuri.zip: install
	rm -f laskuri.zip
	cd stage && zip -r ../laskuri.zip laskuri

install: $(MKPDF_DIR) laskuri
	install -v -m 755 -D -t stage/laskuri/bin $(MKPDF_DIR)/bin/mkpdf
	install -v -m 755 -D -t stage/laskuri laskuri
	cp -rv LICENSE laskuri.lua fonts data lua stage/laskuri

.PHONY: install

clean:
	rm -rf stage
	rm laskuri

.PHONY: clean

$(MKPDF_ARCHIVE):
	curl -J -O -L https://github.com/oswjk/mkpdf/releases/download/v${MKPDF_VERSION}/${MKPDF_ARCHIVE}

$(MKPDF_DIR): $(MKPDF_ARCHIVE)
	unzip $<

laskuri: laskuri.c
	$(LINK.c) -o $@ $<
