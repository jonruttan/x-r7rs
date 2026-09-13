#!/bin/sh
# # x-r7rs -- the R7RS personality for x-lang
#
# ## tests/spec-runner.sh -- the bundle's runner
#
# @description Sources the PLATFORM's spec runner; vendors nothing.
# @author [Jon Ruttan](jonruttan@gmail.com)
# @copyright 2026 Jon Ruttan
# @license MIT No Attribution (MIT-0)
#
#     ., .,
#     {O,O}
#     (   )
#      " "
#
# NOT ONE PATH INTO THE X-LANG SOURCE TREE.  The 2024 runner reached the
# platform as "$SCRIPT_DIR/../../../tests/spec-runner.sh" and both that and
# its X_BIN dangled the moment the personality left the repo -- the failure
# x-lang docs/personality-contract.md calls "addressing, not sharing".
# Everything here comes from x itself: --share-dir says which tree x reads
# from (repo root in a checkout, share/x installed) and --engine-path says
# where the engine is after the wrapper's full discovery order.
#
# Set X to point at a particular x; otherwise the one on PATH is used.
set -e

BUNDLE="$(cd "$(dirname "$0")/.." && pwd)"
X="${X:-x}"

command -v "$X" >/dev/null 2>&1 || {
	echo "x-r7rs: no x on PATH.  Set X=/path/to/x.sh and retry." >&2
	exit 1
}

# --share-dir answers from ANY cwd as of x-lang 990c4a35.  It did not at first:
# mode detection is cwd-based, so a checkout's x.sh asked from outside took the
# installed branch and computed a share/x no checkout has.  This runner used to
# cd to the wrapper's own directory before asking -- the guessing the flag
# exists to end.  Reported, fixed upstream, dance removed.
X_ROOT="$("$X" --share-dir)"
# X_BIN is env-overridable, the way tests/x/spec-runner.sh makes it -- so the
# same runner can drive a variant or patched engine without moving anything.
X_BIN="${X_BIN:-$("$X" --engine-path)}"

# REQUIRED FROM AN INSTALLED TREE.  The runner finds its awk harness from the
# directory holding the ENGINE -- true in a checkout, where the binary sits
# beside tests/, and false in an install, where the engine is under libexec/x.
# A sourced script cannot portably find its own path, so the caller says.
SPEC_RUNNER_DIR="$X_ROOT/tests"
export SPEC_RUNNER_DIR

# The harness is GENERATED, never committed: it embeds two absolute paths
# that are facts of this machine, not of the bundle.
sh "$BUNDLE/tests/gen-harness.sh" "$X_ROOT" "$BUNDLE"

LANG_LIB="$BUNDLE/tests/lib/harness.gen.x"
# SPEC_PATH is env-overridable so a single spec file can be run in isolation
# while diagnosing, without moving anything into the suite.
SPEC_PATH="${SPEC_PATH:-$BUNDLE/tests/specs}"

# THE SUITE BOOTS FROM A STATE IMAGE OF THE HARNESS, when the platform can
# write one -- and for a bundle this size the BOOT is what the suite costs.
# Every spec file is its own process, and each one reads the tower and this
# lang from source before its first case; x-python measured the same shape at
# 26 seconds of boot in a 38-second file, two thirds of its wall clock
# (x-python#43, which is where this block comes from -- x-awk has run this way
# since 2026-09-06).
#
# tools/dev/image-build.sh images a child base that loaded the harness and
# keys the image on what it depends on: the harness, the platform's lib/, its
# engine, and every tree the harness armed -- read back off the generated
# harness itself (its `import-path!` lines are this bundle and, for a lang
# built on another, the lang beneath it), so a change to EITHER rewrites the
# image rather than leaving a stale one that still answers.
#
# The writer lives in a CHECKOUT only; an installed tree, and any release
# older than the image tools, boots from source and says so -- which is what
# the pinned leg does until this bundle's (requires-release ...) names a
# release carrying them.  IMG=0 is the control: the same suite from source,
# one file per process either way, so the boot is the only difference -- and
# it is the FIRST thing to try against a failure that reproduces nowhere
# else, because a stale or wrong image is invisible in a diff.
#
#  RAISE TIMEOUT_UNIT_SECS ON BOTH LEGS WHEN COMPARING THEM, or a loaded box
# decides the answer.  The boot the image removes is ~20s of a 60s per-file
# budget, so the SOURCE leg is the one that runs out: 02-derived timed out on
# a busy machine and reported 49 cases as `died mid-batch`, making the image
# look 49 BETTER than source when nothing differed.  The legs are only
# comparable when neither can be stopped by the clock.
if [ "${IMG:-1}" = 0 ]; then
	SPEC_BATCH="${SPEC_BATCH:-1}"; export SPEC_BATCH
else
	_builder="$X_ROOT/tools/dev/image-build.sh"
	#  ABSENT IS ITS OWN ANSWER, and said once.  Each gate below empties
	# _builder after saying WHY, so "not there" has to be decided here or the
	# fallback prints a second line blaming a file that is present.
	if [ ! -f "$_builder" ]; then
		echo "x-r7rs: no image writer at $_builder -- the suite boots from source" >&2
		_builder=""
	fi
	# A PLATFORM THAT IMAGES ITS JIT TRAMPOLINES CANNOT CARRY AN IMAGE THAT
	# COMPILES, and the failure is a SIGSEGV rather than a wrong answer:
	# tool/asm-compile.x held those addresses as plain integers from dlsym, so
	# an image carries the WRITER process's addresses and a compile on the far
	# side of a load jumps into them (x-python#43 saw exit 139 on the analyser
	# swap).  x-lang 41b93185 made them transients the recache hook remakes;
	# the probe is for the FIX and not for a version, so a platform that has
	# it is used and one that has not boots from source.
	_asm="$X_ROOT/lib/x/tool/asm-compile.x"
	if [ -f "$_asm" ] && ! grep -q "image-transients" "$_asm"; then
		echo "x-r7rs: platform images the JIT trampoline addresses (pre-41b93185) -- the suite boots from source" >&2
		_builder=""
	fi
	#  A PLATFORM WHOSE RECACHE WALK IS SHAPED LIKE R5RS ITERATION CANNOT RUN A
	# HOOK IN THIS BUNDLE, and the failure is a WRONG ANSWER, not a crash.
	# boot/reflect.x's %image-recache! runs AFTER the install, so it runs in the
	# imaged lang's environment -- and r5rs re-means `do` as R5RS iteration, told
	# apart from sequencing by shape.  Spelled (do ((first l)) (self (rest l))),
	# the walk's first operand is a list holding one pair, which IS a binding list
	# by that rule: it visited every hook and called none, in silence.  Every
	# transient stayed nil, float.x's libm handle among them, and this suite went
	# from 27 failures to 220 (126 of them `ffi-call s0->d: nil`) with an image
	# that was itself perfectly valid.  x-lang 5544a80c respells the walk to
	# recurse first; a platform without that boots from source.
	#
	#  COMMENTS ARE STRIPPED BEFORE THE MATCH, and that is not fussiness: the fix
	# QUOTES THE BROKEN SPELLING in the note it leaves behind, so a plain grep
	# answers "broken" on the very platform that carries the fix -- measured, and
	# it silently cost the whole feature on a correct tree.  A probe for a
	# spelling has to read only the code.
	_rfl="$X_ROOT/lib/x/boot/reflect.x"
	if [ -f "$_rfl" ] && sed 's/;.*//' "$_rfl" | grep -q 'do ((first l))'; then
		echo "x-r7rs: platform's %image-recache! walk is shaped like R5RS iteration (pre-5544a80c) -- no hook would run; the suite boots from source" >&2
		_builder=""
	fi
	if [ -n "$_builder" ]; then
		# The trees the harness armed, in the order it armed them.
		_keys=$(sed -n 's/^(import-path! "\(.*\)")$/\1/p' "$LANG_LIB")
		#  THIS BUNDLE DECLARES HOW ITS MODULES ARE SPELT.  image-build.sh keys
		# a KEY-PATH by extension and knows only the platform's own .x -- the
		# caller that arms a tree is the only thing that can know the rest, and
		# nine of this bundle's language files are .scm: its scm/ layer IS the
		# R5RS and R7RS library.  Unkeyed, editing one left the image "current"
		# and the suite tested the library that was there BEFORE while IMG=0
		# tested the one on disk: both legs green, at two different libraries.
		#
		# A BUILDER WITHOUT THIS DOOR IGNORES THE VARIABLE AND SAYS NOTHING, so
		# this line is only load-bearing because lang.xon pins a release that
		# has it -- x-lang v0.14.0, which is where IMG_KEY_EXT arrived
		# (x-lang#652).  Moving the pin BACK below that release silently
		# restores the stale image, so the two move together.
		if IMG_KEY_EXT="x scm" X_BIN="$X_BIN" sh "$_builder" "$LANG_LIB" "$BUNDLE/tests/lib/.images" $_keys; then
			X_IMG_DIR="$BUNDLE/tests/lib/.images"; export X_IMG_DIR
		else
			echo "x-r7rs: no state image (image-build exit $?) -- the suite boots from source" >&2
		fi
	fi
fi

. "$X_ROOT/tests/spec-runner.sh"
