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

x-r7rs is a **lang**: a surface language loaded over an x-lang dialect, free
to re-mean shared spellings. The terms are in x-lang's
[lang contract](https://github.com/jonruttan/x-lang/blob/main/docs/lang-contract.md).

It is the first lang built on another lang rather than straight on the
platform — `lang.xon` declares that dependency and x refuses at startup, by
name, if it is missing.

## Status

**594 of 637 specs green** against x-lang **v0.8.1** and x-r5rs **v0.2.1**.

The 43 that do not pass are recorded by name in
[`tests/contract/known-failures.txt`](tests/contract/known-failures.txt), and
CI gates on that list rather than on a count — red when a new failure appears
*and* red when a recorded one starts passing. Documented debt can ship; a
regression cannot.

| | count | why |
|---|---|---|
| **Bytevectors** | 23 | `x/bytevector.x` not loaded — raw FFI against `obj-make`, which no longer exists. |
| **Error objects and `guard`** | 16 | `error-object?` and friends; one edge of the clause dispatcher. |
| **Numerics and `cond-expand`** | 4 | `4.0` where the 2024 suite expects `4`, and one feature-id case. |

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

## Pin it instead, for a project

An install is unversioned and machine-wide. When it matters *which* version a
project builds against, pin it — `Pin bundle` verifies the tarball against a
digest before unpacking. In the project's `lang.pin.xon`:

```x
(lang "r7rs")
(release "v0.1.0")
(bundle "sha256:…" "https://github.com/jonruttan/x-r7rs/releases/download/v0.1.0/x-r7rs-v0.1.0.tar.gz")
(source "https://github.com/jonruttan/x-r7rs.git")
```

The exact block, digest filled in, is published with each release.

## The r5rs dependency

`lang.xon` carries it as a row, not a probe:

```x
(requires-lang "r5rs" "v0.2.1")
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

**v0.2.1 is what the row declares**, because the comparison is equality rather
than a minimum: it answers *which x-r5rs was this built and tested against*,
and only that version satisfies it. v0.2.1 changed no library file — it is
v0.2.0 plus the lang kit and the x-lang v0.8.0 pairing (release-ref: history)
that it carried — so the floor has not moved, only the pairing.

Working on both at once, `--allow-lang-skew` is the way through.

## Running it

```bash
make test     # the spec suite -- every failure is loud
make check    # the suite against known-failures.txt -- what CI gates on
make bundle   # roll a release tarball and print its pin
```

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

## Licence

MIT No Attribution (MIT-0). See [LICENSE](LICENSE).
