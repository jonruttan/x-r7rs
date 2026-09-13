#!/bin/sh
# # x-r7rs -- the R7RS lang for x-lang
#
# ## tests/spec-runner.sh -- the bundle's runner
#
# @description Sources the platform's spec runner; vendors nothing.
# @author [Jon Ruttan](jonruttan@gmail.com)
# @copyright 2026 Jon Ruttan
# @license MIT No Attribution (MIT-0)
#
#     ., .,
#     {O,O}
#     (   )
#      " "
#
# No path reaches into an x-lang source tree; everything comes from x itself.
# --share-dir gives the tree x reads from (repo root in a checkout, share/x
# when installed) and --engine-path gives the engine location after the
# wrapper's discovery order.
#
# Set X to point at a particular x; otherwise the one on PATH is used.
set -e

BUNDLE="$(cd "$(dirname "$0")/.." && pwd)"
X="${X:-x}"

command -v "$X" >/dev/null 2>&1 || {
	echo "x-r7rs: no x on PATH.  Set X=/path/to/x.sh and retry." >&2
	exit 1
}

# --share-dir answers from any cwd.
X_ROOT="$("$X" --share-dir)"
# X_BIN is env-overridable, the way tests/x/spec-runner.sh makes it -- so the
# same runner can drive a variant or patched engine without moving anything.
X_BIN="${X_BIN:-$("$X" --engine-path)}"

# The platform runner locates its awk harness relative to the engine binary,
# which sits beside tests/ in a checkout but under libexec/x in an install; a
# sourced script cannot portably find its own path, so the caller sets this.
SPEC_RUNNER_DIR="$X_ROOT/tests"
export SPEC_RUNNER_DIR

# The harness is GENERATED, never committed: it embeds two absolute paths
# that are facts of this machine, not of the bundle.
sh "$BUNDLE/tests/gen-harness.sh" "$X_ROOT" "$BUNDLE"

LANG_LIB="$BUNDLE/tests/lib/harness.gen.x"
# SPEC_PATH is env-overridable so a single spec file can be run in isolation
# while diagnosing, without moving anything into the suite.
SPEC_PATH="${SPEC_PATH:-$BUNDLE/tests/specs}"

# The suite boots from a state image of the harness when the platform can write
# one; for a bundle this size the boot is most of the cost (each spec file is
# its own process and reads the tower and this lang from source before its
# first case). tools/dev/image-build.sh images a child base that loaded the
# harness and keys the image on what it depends on -- the harness, the
# platform's lib/, its engine, and every tree the harness armed (read back off
# the generated harness's import-path! lines, so a change to this bundle or the
# lang beneath it rewrites the image rather than leaving a stale one).
#
# The writer lives in a checkout only; an installed tree, and any release older
# than the image tools, boots from source and says so. IMG=0 is the control:
# the same suite from source, one file per process either way, so the boot is
# the only difference -- and the first thing to try against a failure that
# reproduces nowhere else, since a stale image is invisible in a diff.
#
# Raise TIMEOUT_UNIT_SECS on both legs when comparing them: the boot the image
# removes is a large part of the per-file budget, so the source leg is the one
# that can time out, which would make the image look better than source when
# nothing differs.
if [ "${IMG:-1}" = 0 ]; then
	SPEC_BATCH="${SPEC_BATCH:-1}"; export SPEC_BATCH
else
	_builder="$X_ROOT/tools/dev/image-build.sh"
	# Absent is its own answer, said once: each gate below empties _builder
	# after saying why, so "not there" is decided here rather than letting the
	# fallback blame a file that is present.
	if [ ! -f "$_builder" ]; then
		echo "x-r7rs: no image writer at $_builder -- the suite boots from source" >&2
		_builder=""
	fi
	# A platform that images its JIT trampolines cannot carry an image that
	# compiles: tool/asm-compile held those addresses as plain integers from
	# dlsym, so an image would carry the writer process's addresses and a
	# compile after a load would jump into them. x-lang 41b93185 made them
	# transients the recache hook remakes; the probe is for that fix, not a
	# version, so a platform without it boots from source.
	_asm="$X_ROOT/lib/x/tool/asm-compile.x"
	if [ -f "$_asm" ] && ! grep -q "image-transients" "$_asm"; then
		echo "x-r7rs: platform images the JIT trampoline addresses (pre-41b93185) -- the suite boots from source" >&2
		_builder=""
	fi
	# A platform whose recache walk is shaped like R5RS iteration cannot run a
	# hook in this bundle, and the failure is a wrong answer, not a crash:
	# boot/reflect.x's %image-recache! runs after the install, in the imaged
	# lang's environment, and r5rs re-means `do` as R5RS iteration told apart
	# from sequencing by shape. x-lang 5544a80c respells the walk to recurse
	# first; a platform without that boots from source. Comments are stripped
	# before the match, because the fix quotes the broken spelling in its own
	# note, so a probe for a spelling must read only the code.
	_rfl="$X_ROOT/lib/x/boot/reflect.x"
	if [ -f "$_rfl" ] && sed 's/;.*//' "$_rfl" | grep -q 'do ((first l))'; then
		echo "x-r7rs: platform's %image-recache! walk is shaped like R5RS iteration (pre-5544a80c) -- no hook would run; the suite boots from source" >&2
		_builder=""
	fi
	if [ -n "$_builder" ]; then
		# The trees the harness armed, in the order it armed them.
		_keys=$(sed -n 's/^(import-path! "\(.*\)")$/\1/p' "$LANG_LIB")
		# This bundle declares how its modules are spelt. image-build.sh keys a
		# KEY-PATH by extension and knows only the platform's own .x; nine of
		# this bundle's language files are .scm (its scm/ layer is the R5RS and
		# R7RS library), so unkeyed, editing one would leave the image current
		# while the suite tested the previous library. This line is load-bearing
		# only because lang.xon pins a release with IMG_KEY_EXT (x-lang v0.14.0,
		# x-lang#652); a builder without the door ignores the variable, so the
		# pin and this move together.
		if IMG_KEY_EXT="x scm" X_BIN="$X_BIN" sh "$_builder" "$LANG_LIB" "$BUNDLE/tests/lib/.images" $_keys; then
			X_IMG_DIR="$BUNDLE/tests/lib/.images"; export X_IMG_DIR
		else
			echo "x-r7rs: no state image (image-build exit $?) -- the suite boots from source" >&2
		fi
	fi
fi

. "$X_ROOT/tests/spec-runner.sh"
