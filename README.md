# x-r7rs — R7RS Scheme on x-lang

R7RS-small as a thin layer over
[x-r5rs](https://github.com/jonruttan/x-r5rs): `case-lambda`, records,
parameters, promises, `cond-expand`, string ports, and the R7RS additions to
the standard library.

```
$ x -l r7rs
> (define-record-type point (make-point x y) point? (x point-x) (y point-y))
> (point-x (make-point 3 4))
3
> ((case-lambda ((a) a) ((a b) (+ a b))) 3 4)
7
> (let ((p (open-output-string))) (display "hi" p) (get-output-string p))
"hi"
```

x-r7rs is a **lang**: a surface language loaded over an
[x-lang](https://github.com/jonruttan/x-lang) dialect. Where
x-lang and Scheme spell something the same way, Scheme is free to mean
something different by it. The terms are in x-lang's
[lang contract](https://github.com/jonruttan/x-lang/blob/main/docs/lang-contract.md).

It is the first lang built on another lang rather than straight on the
platform — `lang.xon` declares that dependency and x refuses at startup, by
name, if it is missing.

## Status

**610 of 637 specs green** against x-lang **v0.9.0** and x-r5rs **v0.2.2**.

Sixteen of the recorded failures went on v0.9.0 without a line changing under
`r7rs/` — the whole error-object surface and every `guard` case but one. The
contract shrank from 43 to 27 because the ratchet is red in *both* directions,
so a fix cannot land unrecorded.

The 27 that do not pass are recorded by name in
[`tests/contract/known-failures.txt`](tests/contract/known-failures.txt), and
CI gates on that list rather than on a count — red when a new failure appears
*and* red when a recorded one starts passing. Documented debt can ship; a
regression cannot.

| | count | why |
|---|---|---|
| **Bytevectors** | 23 | `x/bytevector.x` not loaded — raw FFI against `obj-make`, which no longer exists. |
| **`guard` with `else`** | 1 | the last of a group of 16; every other clause form passes, so it is the clause dispatcher rather than error objects. |
| **Numerics** | 3 | `4.0` where the 2024 suite expects `4`. |

## Install

Nothing cloned, from any directory:

```bash
x --install-lang https://github.com/jonruttan/x-r5rs/releases/latest/download/lang.pin.xon
x --install-lang https://github.com/jonruttan/x-r7rs/releases/latest/download/lang.pin.xon
x -l r7rs
```

x fetches each published pin, then the tarball it names, verifies the digest,
and installs to `<share>/langs/` — where `x -l` looks. **Install x-r5rs
first**: x-r7rs requires it and will say so by name if it is absent.

From a clone, if you have one:

```bash
make install                      # into the x on your PATH
PREFIX=$HOME/.local make install  # or a particular prefix
```

`make uninstall` removes it either way.

**One trap, and it is the one you will hit.** `x` decides where to look for
langs from the directory you run it *in*. Inside an **x-lang checkout** it
searches `deps/langs/` and an installed lang is invisible, however correctly it
was installed:

```
$ cd path/to/x-lang && x -l r7rs
Error: no library, app or lang named 'r7rs'
  searched lib/r7rs.x, apps/r7rs/run.x
      and deps/langs/*/lang.xon
```

Run it from anywhere else, or name the bundles explicitly — `X_LANG_DIR` wins
in both modes:

```bash
X_LANG_DIR=$HOME/.local/share/x/langs/ x -l r7rs   # the installed one
X_LANG_DIR=/path/to/x-r7rs/.. x -l r7rs            # a checkout, uninstalled
```


## Pin it instead, for a project

An install is unversioned and machine-wide. When it matters *which* version a
project builds against, pin it — `Pin bundle` verifies the tarball against a
digest before unpacking. In the project's `lang.pin.xon`:

```x
(lang "r7rs")
(release "v0.1.3")
(bundle "sha256:…" "https://github.com/jonruttan/x-r7rs/releases/download/v0.1.3/x-r7rs-v0.1.3.tar.gz")
(source "https://github.com/jonruttan/x-r7rs.git")
```

The exact block, digest filled in, is published with each release.

## The r5rs dependency

`lang.xon` carries it as a row, not a probe:

```x
(requires-lang "r5rs" "v0.2.2")
```

x resolves it the same way it resolves `-l`, arms r5rs's root *before* this
bundle's own so anything shared here still wins, and refuses at startup naming
what is missing and who asked for it. The version is compared for **equality**,
never parsed, and what it compares against is derived — `make install` and
`tools/bundle.sh` stamp a version from the tag, because a version written into
a dependency's own manifest could only be true at the one commit that gets
tagged.

**v0.2.0 is where the capability landed** — the string ports here are built on
that release's polymorphic port source and sink, and against v0.1.0 x-r7rs does
not fail a spec, it fails to load.

**v0.2.2 is what the row declares**, because the comparison is equality rather
than a minimum: it answers *which x-r5rs was this built and tested against*,
and only that version satisfies it. Nothing under `r5rs/` has changed since
v0.2.0 — the releases since are the lang kit and successive x-lang pairings —
so the floor has not moved, only the pairing.

That is also the cost of equality matching: every x-r5rs release obsoletes this
row, so the two move in lockstep. It is the price of *never parsed*, paid
deliberately instead of building a resolver.

Working on both at once, `--allow-lang-skew` is the way through.

## Running it

```bash
x -l r7rs                  # interactive
x -l r7rs -f program.scm   # batch
```

x-lang boots the dialect `lang.xon` declares, resolves and arms x-r5rs's root,
then this bundle's own on top of it — which is why nothing here needs to know a
path.

## Development

```bash
X=/path/to/x-lang/x.sh make test    # the spec suite -- every failure is loud
X=/path/to/x-lang/x.sh make check   # the suite against known-failures.txt -- what CI gates on
make check-release-refs             # the declared versions are named in one place
make bundle                         # roll a release tarball and print its pin
```

**Pass `X` explicitly.** Without it the suite takes the `x` on your PATH, and an
installed x that trails the checkout reports failures the platform has already
fixed.

**Do not `make install` into an x-lang checkout.** The Makefile asks
`$(X) --share-dir` where to put the bundle, and a checkout answers with its own
root — so the files land in `<checkout>/langs/NAME`, which is not one of the
three paths `-l` searches there. It reports success and the lang stays
invisible. Install into a real `<share>` tree, or use `X_LANG_DIR`.


**And this bundle needs an x-r5rs it can resolve.** A checkout of x-r5rs does
not satisfy the row — only an install or an unpacked release tarball carries
the stamped `version` file the comparison reads. That stamp is `git describe`,
so installing x-r5rs from a checkout that is not exactly on its tag produces
something like `v0.2.2-1-gabc1234-dirty`, which is not `v0.2.2` and is refused
by name. `--allow-lang-skew` is the way through while working on both at once.

CI runs the declared release *and* x-lang `main`, so a platform that moves
underneath this bundle shows up as a red build rather than a surprise later.

## Layout

```
lang.xon            what this bundle IS -- name, dialect, dependencies
run.x               the entry point lang.xon names
r7rs/base.x         the load order
r7rs/scm/*.scm      the language, in Scheme
r7rs/x/*.x          the parts that need x itself
tests/specs/        the suite, as literate markdown
tests/contract/     the recorded debt CI gates on
docs/               the R7RS reports, and notes from the port
```

## Background

R7RS is Scheme's answer to its own schism: R6RS (2007) grew the language
enough that part of the community declined to follow, so the successor was
chartered as two languages. R7RS-small — ratified 2013, edited by Alex Shinn,
John Cowan and Arthur Gleckler — returns to R5RS's size and spirit while
fixing what experience had settled: records, exceptions and `guard`,
bytevectors, string ports, parameters, `cond-expand`, and a library system.
That delta is exactly what this bundle is: R5RS plus about 700 lines. The
large edition remains a work in progress.

- [R7RS-small](https://small.r7rs.org/) — the report
- [srfi.schemers.org](https://srfi.schemers.org/) — the SRFI library, where Scheme features incubate
- [standards.scheme.org](https://standards.scheme.org/) — every report, R1RS through R7RS

## Licence

MIT No Attribution (MIT-0). See [LICENSE](LICENSE).
