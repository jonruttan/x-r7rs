# x-r7rs -- the R7RS lang for x-lang
#
# Install copies this bundle to <share>/langs/r7rs, where `x -l` looks: a lang
# is installed when its files are there. No registry, no database.
#
#   make install                        into the x on PATH
#   PREFIX=$HOME/.local make install    into a particular prefix
#
# A pin (lang.pin.xon + Pin bundle) freezes a verified tarball for one project
# and is what a build should depend on. An install is one unversioned copy for
# the whole machine. Pin when the version matters; install to get `x -l r7rs`
# working.

X ?= x

# The version is derived from git describe, never committed: a version literal
# is true only at the commit it is tagged on and wrong on every commit after.
# lang.xon declares what this bundle requires; the installed artifact carries
# what it is, in a version stamp -- the same split as x-lang's own
# $(X_RELEASE) -> <lib>/contract/release.
LANG_VERSION ?= $(shell git describe --tags --always --dirty 2>/dev/null || echo dev)
# PREFIX wins when given, so this matches x-lang's own `PREFIX=... make
# install`.  Otherwise ask the x on PATH where its tree is -- the question
# --share-dir exists to answer.
SHARE := $(if $(PREFIX),$(PREFIX)/share/x,$(shell $(X) --share-dir))
DEST  := $(SHARE)/langs/r7rs

# What a consumer needs to run the lang: the declaration, the entry, the
# modules. Not the suite, the tooling, or CI.
PAYLOAD := lang.xon run.x r7rs

.PHONY: install
install: ## Install into <share>/langs/r7rs
	@test -n "$(SHARE)" || { echo "x-r7rs: cannot find an x tree -- set PREFIX or X" >&2; exit 1; }
	@test -d "$(SHARE)" || { echo "x-r7rs: no x tree at $(SHARE)" >&2; exit 1; }
	rm -rf "$(DEST)"
	mkdir -p "$(DEST)"
	cp -R $(PAYLOAD) "$(DEST)/"
	printf '%s\n' '$(LANG_VERSION)' > "$(DEST)/version"
	@echo "x-r7rs: installed to $(DEST)"
	@echo "x-r7rs: writing the boot image"
	"$(X)" --image -l r7rs || true
	@echo "x-r7rs: try  x -l r7rs"

.PHONY: uninstall
uninstall: ## Remove it again
	rm -rf "$(DEST)"
	@echo "x-r7rs: removed $(DEST)"

.PHONY: test
test: ## Run the spec suite (every failure is loud)
	X="$(X)" sh tests/spec-runner.sh

.PHONY: check
check: check-release-refs check-if-ladders ## Run the suite against tests/contract/known-failures.txt -- what CI gates on
	X="$(X)" sh tests/spec-gate.sh

# Seconds, and no platform needed: it reads lang.xon and greps the tree.  It
# rides `check` rather than a tier of its own because what it catches -- a
# README naming a pairing nobody tested -- ships silently otherwise.
.PHONY: check-release-refs
check-release-refs: ## Assert the declared x-lang and x-r5rs versions are named once
	X="$(X)" sh tools/check/release-refs.sh

# `match` is the primitive for a decision with arms; a nested-if chain is not.
# It rides `check` for the same reason release-refs does -- the shape it
# catches is invisible in a diff that only shows the new arm.
.PHONY: check-if-ladders
check-if-ladders: ## Assert no new nested-if ladders (tools/contract/if-ladders.txt)
	X="$(X)" sh tools/check/if-ladders.sh

.PHONY: bundle
bundle: ## Roll a release tarball and print its pin
	sh tools/bundle.sh

.PHONY: help
help: ## Show targets
	@awk 'BEGIN {FS = ":.*?## "} /^[a-zA-Z0-9_-]+:.*?## / {printf "  \033[32m%-12s\033[0m %s\n", $$1, $$2}' $(MAKEFILE_LIST)
