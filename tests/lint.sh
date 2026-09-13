#!/bin/sh
# # x-r7rs -- R7RS Scheme on x-lang
#
# ## tests/lint.sh -- shim onto the lang kit's linter
#
# @description Sources the PLATFORM's lint; vendors nothing.  --strict
#   fails on the structural rules, which is how this bundle wants them.
# @author [Jon Ruttan](jonruttan@gmail.com)
# @copyright 2026 Jon Ruttan
# @license MIT No Attribution (MIT-0)
#
#     ., .,
#     {O,O}
#     (   )
#      " "
#
# THE BUNDLE WAS SWEPT BY NOTHING, and this one could not be swept at all.
# x-r7rs stands on x-r5rs -- r7rs/base.x reads %r5rs-repl-print at LOAD time
# -- and the linter's preload knew nothing of `(requires-lang ...)`, so
# importing that sibling to bind it for the rest of the directory killed the
# engine: every file in every group, `(no verdict -- engine died mid-group)`
# under one Unbound SYMBOL.  x-lang#689 reads the row.
#
# tools/check/if-ladders.sh stays.  It is one rule with its own ratchet file,
# written here because the platform sweep that knows it could not be pointed
# at a bundle; that sweep can be now, and a second opinion on a rule nothing
# else ever cross-checked is worth having.
#
# R5RS_ROOT is honoured by the platform's preload exactly as gen-harness.sh
# honours it, so a CI step that sets it for the specs sets it for this too.
#
# X_LANG_KIT names a checkout's tools/lang-kit directly, the spelling
# tests/spec-gate.sh already takes; otherwise the kit is found where x says
# its share tree is.
set -e

BUNDLE="$(cd "$(dirname "$0")/.." && pwd)"
X="${X:-x}"

command -v "$X" >/dev/null 2>&1 || {
	echo "x-r7rs: no x on PATH.  Set X=/path/to/x and retry." >&2
	exit 2
}

# The tree the kit's lint.sh will actually read, whatever X_LANG_KIT says:
# it resolves its linter from --share-dir, so that is what the probe below
# has to judge.
X_ROOT="$("$X" --share-dir)"
KIT="${X_LANG_KIT:-$X_ROOT/tools/lang-kit}"

# A GATE THE PLATFORM CANNOT RUN YET SKIPS; it does not fail the build.
# tests/spec-gate.sh hard-fails on a missing kit and that is right for a file
# every x has shipped for months.  The linter is newer, and the fix this
# bundle needs is newer still, so hard-failing here would break `make check`
# on every x that exists until a release lands -- a cadence this bundle does
# not set.
[ -f "$KIT/lint.sh" ] || {
	echo "x-r7rs: SKIPPING lint -- no $KIT/lint.sh in this x." >&2
	echo "x-r7rs: it arrives with the lang kit's linter; upgrade x to gate on it." >&2
	exit 0
}

# THE CAPABILITY, NOT THE VERSION NUMBER.  A version test would misjudge
# every tree between releases, which is what CI's `main` leg is.  These
# names are the fixes themselves:
#
#   _required_langs_preload -- x-lang#689, the one this bundle cannot be
#     linted without: the preload reading `(requires-lang "r5rs" ...)` and
#     arming that bundle ahead of this one.
#
#   build/boot/x-base.x -- x-lang#687.  A CHECKOUT keeps the boot amalgam at
#     build/boot/, an install at boot/, and only the installed path was
#     looked for.  This bundle's CI points X at a checkout's ./x.sh, so
#     without it the gate cannot run in CI at all.
#
# #689 sits on #687, so either absent means the same thing; both are named
# because a probe that explains itself is worth two greps.
if ! grep -q '_required_langs_preload' "$X_ROOT/tools/dev/lint.sh" 2>/dev/null ||
   ! grep -q 'build/boot/x-base.x' "$X_ROOT/tools/dev/lint.sh" 2>/dev/null; then
	echo "x-r7rs: SKIPPING lint -- this x's linter cannot arm the lang this" >&2
	echo "x-r7rs: bundle is written on top of (x-lang#687, #689), so every" >&2
	echo "x-r7rs: file would die on Unbound SYMBOL.  Upgrade x to gate on it." >&2
	exit 0
fi

# WHAT THIS GATE DOES NOT CATCH TODAY, written here rather than discovered
# later: the linter's `Undefined` rule is DEAD in this bundle, as it is in
# x-r5rs -- which is the bundle underneath, and almost certainly why.  Plant
# `(def %probe (fn (_) (undefined-name-alpha 1)))` in r7rs/printer.x and this
# gate still says ok, while x-krn reports the same plant correctly.  Measured
# cause: under the preload the linter records ZERO uses for the file, so the
# rule has nothing to filter.  x-lang#690 carries the reproduction.
#
# The STRUCTURAL rules DO fire -- a planted four-arm ladder is reported -- and
# those are what --strict gates on, so this is worth running.  It is just not
# yet the undefined-name check it looks like.
#
# No targets are named: the kit's default is every .x the bundle ships minus
# the generated harness -- r7rs/, r7rs/x/ and tools/check/, all worth sweeping.
BUNDLE="$BUNDLE" X="$X" sh "$KIT/lint.sh" --strict "$@"
