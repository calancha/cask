export CASK ?= bin/cask
export EMACS ?= emacs
export CASK_DIR := $(shell EMACS=$(EMACS) $(CASK) package-directory)
SERVANT ?= servant
SPHINX-BUILD = sphinx-build
SPHINXFLAGS =

SERVANT_DIR = servant
SERVANT_TMP_DIR = $(SERVANT_DIR)/tmp
SERVANT_PACKAGES_DIR = $(SERVANT_DIR)/packages
SERVANT_NEW_PACKAGES_DIR = $(SERVANT_DIR)/new-packages
SERVANT_ARCHIVE_CONTENTS = $(SERVANT_PACKAGES_DIR)/archive-contents
SERVANT_NEW_ARCHIVE_CONTENTS = $(SERVANT_NEW_PACKAGES_DIR)/archive-contents

DOCBUILDDIR=build/doc
DOCTREEDIR=$(DOCBUILDDIR)/doctrees

FIXTURES_DIR = fixtures

all: test

test: cask unit ecukes

cask: $(CASK_DIR)

$(CASK_DIR): Cask
	$(CASK) install
	touch $(CASK_DIR)

unit:
	$(MAKE) start-server
	bash -c "trap 'trap \"\" EXIT ; $(MAKE) -C $(CURDIR) stop-server' EXIT ; $(CASK) exec ert-runner -L ./test -l test/test-helper.el test/cask-*test.el | tee /tmp/cask.unit.out"
	! (grep -q "unexpected results" /tmp/cask.unit.out)

ecukes:
	$(MAKE) start-server
	bash -c "trap 'ret=$$? ; trap \"\" EXIT ; $(MAKE) -C $(CURDIR) stop-server; exit $$ret' EXIT ; $(CASK) exec ecukes --reporter magnars"

doc: html

html:
	$(SPHINX-BUILD) -b html -d $(DOCTREEDIR) $(SPHINXFLAGS) doc $(DOCBUILDDIR)/html

linkcheck :
	$(SPHINX-BUILD) -b linkcheck -d $(DOCTREEDIR) $(SPHINXFLAGS) doc $(DOCBUILDDIR)/linkcheck

start-server: cask $(SERVANT_DIR)
	$(CASK) exec $(SERVANT) start > $(SERVANT_TMP_DIR)/servant.log 2>&1 &

stop-server:
	kill $$(cat $(SERVANT_TMP_DIR)/servant.pid)

$(SERVANT_DIR): clean
$(SERVANT_DIR): $(SERVANT_TMP_DIR)
$(SERVANT_DIR): $(SERVANT_PACKAGES_DIR)/archive-contents
$(SERVANT_DIR): $(SERVANT_NEW_PACKAGES_DIR)/archive-contents

$(SERVANT_TMP_DIR):
	@mkdir -p $@

$(SERVANT_PACKAGES_DIR):
	@mkdir -p $@

$(SERVANT_NEW_PACKAGES_DIR):
	@mkdir -p $@

$(SERVANT_PACKAGES_DIR)/package-a-0.0.1.el: $(SERVANT_PACKAGES_DIR)
	cp $(FIXTURES_DIR)/package-a-0.0.1/package-a.el $@

$(SERVANT_PACKAGES_DIR)/package-b-0.0.1.el: $(SERVANT_PACKAGES_DIR)
	cp $(FIXTURES_DIR)/package-b-0.0.1/package-b.el $@

$(SERVANT_PACKAGES_DIR)/package-c-0.0.1.tar: $(SERVANT_PACKAGES_DIR)
	tar -cvf $@ -C $(FIXTURES_DIR) package-c-0.0.1

$(SERVANT_PACKAGES_DIR)/package-d-0.0.1.tar: $(SERVANT_PACKAGES_DIR)
	tar -cvf $@ -C $(FIXTURES_DIR) package-d-0.0.1

$(SERVANT_PACKAGES_DIR)/package-e-0.0.1.tar: $(SERVANT_PACKAGES_DIR)
	tar -cvf $@ -C $(FIXTURES_DIR) package-e-0.0.1

$(SERVANT_PACKAGES_DIR)/package-f-0.0.1.el: $(SERVANT_PACKAGES_DIR)
	cp $(FIXTURES_DIR)/package-f-0.0.1/package-f.el $@

$(SERVANT_NEW_PACKAGES_DIR)/package-a-0.0.2.el: $(SERVANT_NEW_PACKAGES_DIR)
	cp $(FIXTURES_DIR)/package-a-0.0.2/package-a.el $@

$(SERVANT_ARCHIVE_CONTENTS): $(SERVANT_PACKAGES_DIR)/package-a-0.0.1.el
$(SERVANT_ARCHIVE_CONTENTS): $(SERVANT_PACKAGES_DIR)/package-b-0.0.1.el
$(SERVANT_ARCHIVE_CONTENTS): $(SERVANT_PACKAGES_DIR)/package-c-0.0.1.tar
$(SERVANT_ARCHIVE_CONTENTS): $(SERVANT_PACKAGES_DIR)/package-d-0.0.1.tar
$(SERVANT_ARCHIVE_CONTENTS): $(SERVANT_PACKAGES_DIR)/package-e-0.0.1.tar
$(SERVANT_ARCHIVE_CONTENTS): $(SERVANT_PACKAGES_DIR)/package-f-0.0.1.el
	$(CASK) exec $(SERVANT) index --packages-path $(SERVANT_PACKAGES_DIR)

$(SERVANT_NEW_ARCHIVE_CONTENTS): $(SERVANT_NEW_PACKAGES_DIR)/package-a-0.0.2.el
	$(CASK) exec $(SERVANT) index --packages-path $(SERVANT_NEW_PACKAGES_DIR)

clean:
	rm -rf $(SERVANT_DIR)
	rm -rf $(DOCBUILDDIR)

.PHONY: start-server stop-server unit ecukes test all clean \
	doc html linkcheck cask

.SILENT: start-server stop-server
