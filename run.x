; # x-r7rs -- R7RS Scheme on x-lang
;
; ## run.x -- THE entry, and the only file here that may know a path
;
; @description R7RS Scheme: the Scheme vocabulary and binding forms, on
;   x-lang's evaluator and numeric tower.
; @author [Jon Ruttan](jonruttan@gmail.com)
; @copyright 2026 Jon Ruttan
; @license MIT No Attribution (MIT-0)
;
;     ., .,
;     {O,O}
;     (   )
;      " "
;
; Usage today (until `-l` grows a personality-root step, see README):
;   x.sh -F path/to/x-r7rs/run.x     interactive
;   x.sh -f path/to/x-r7rs/run.x     batch, program on stdin
;
; THE ONE FILE WITH LAYOUT KNOWLEDGE.  Every other file in this bundle
; resolves its siblings by `import`, so the bundle relocates.  That rule is
; the whole reason the last generation of personalities died -- see
; x-lang docs/personality-contract.md, "Why the last generation rotted".
; XENON, NOT x-core, and the dialect row in personality.xon is what says so.
; Scheme's numerics ARE the tower: string->number falls back to %float, and
; 20-numeric-tower.spec.md exercises rationals and complexes.  Booting x-core
; here instead gets you `Unbound SYMBOL '%fsqrt` at the first (sqrt 2) -- which
; is precisely the failure (dialect ...) exists to turn into a refusal at
; acquisition rather than a crash in use.
;
; boot/xenon.x is the launcher-free body; lib/xe.x is that plus the REPL
; launcher this file supplies itself.
(include "lib/x/boot/xenon.x")

; --- Where this bundle lives ------------------------------------------------
; THE ENTRY CANNOT ASK.  x.sh CATS the entry into the engine's stdin rather
; than including it, so inside this file %include-curdir is "." and
; %install-root is unbound in a checkout.  An entry has no way to learn its
; own path -- which is why Logo's names its root with a literal and why the
; contract exempts entries from the path-literal lint.  Logo can get away
; with one literal because Logo lives INSIDE the platform tree; a bundle,
; by definition, does not.  That gap is the "searched personality root,
; extended by one step" the contract still lists as proposed.
;
; So: probe, and say so when nothing answers.  Every candidate below is a
; place a bundle actually sits today; the list shrinks to one line the day
; -l learns a personality root.
(def %r7rs-entry-candidates
  (list
    ; installed tree, or a checkout with apps/r7rs symlinked at the bundle
    (guard (_ "apps/r7rs") (%path-join %install-root "apps/r7rs"))
    ; checkout, cwd at the repo root -- what `x.sh -l r7rs` gives today
    "apps/r7rs"
    ; the entry was INCLUDED rather than piped (a harness, or `include`)
    (guard (_ ".") (%include-curdir))))
(def %r7rs-entry-find-root
  (fn (self roots)
    (if (null? roots)
      ()
      (if (Sys file-exists? (%path-join (first roots) "r7rs/base.x"))
        (first roots)
        (self (rest roots))))))
(def %r7rs-entry-bundle-root (%r7rs-entry-find-root %r7rs-entry-candidates))
(if (null? %r7rs-entry-bundle-root)
  (do
    ; Legible, not a bare "include: cannot open".  A refusal that names what
    ; it looked for is the difference between a five-minute fix and the
    ; afternoon the last generation of these cost.
    (display "x-r7rs: cannot find the bundle root -- no r7rs/base.x under:")
    (newline)
    (def %r7rs-entry-say
      (fn (self roots)
        (if (null? roots)
          ()
          (do
            (display "  ")
            (display (%path-join (first roots) "r7rs/base.x"))
            (newline)
            (self (rest roots))))))
    (%r7rs-entry-say %r7rs-entry-candidates)
    (display "Run from the x-lang repo root with apps/r7rs pointing here, or")
    (newline)
    (display "install the bundle under <install-root>/apps/r7rs.")
    (newline)
    (Sys exit 1))
  ())
(import-path! %r7rs-entry-bundle-root)

; --- The bundle this bundle stands on ---------------------------------------
; R7RS IS AN EXTENSION OF R5RS, and this is the first personality to depend on
; another one.  The contract has no vocabulary for that: personality.xon says
; name, dialect, release and entry, and nothing says "and it needs x-r5rs".
; So the root is probed the same way this bundle's own is, and the refusal
; below names what it looked for.  x-lang#526 asks for the manifest row.
(def %r7rs-r5rs-candidates
  (list
    ; installed tree, or a checkout with apps/r5rs symlinked at that bundle
    (guard (_ "apps/r5rs") (%path-join %install-root "apps/r5rs"))
    "apps/r5rs"
    ; the ordinary development layout: the two bundles as siblings
    (%path-join %r7rs-entry-bundle-root "../x-r5rs")))
(def %r7rs-find-r5rs
  (fn (self roots)
    (if (null? roots)
      ()
      (if (Sys file-exists? (%path-join (first roots) "r5rs/base.x"))
        (first roots)
        (self (rest roots))))))
(def %r7rs-r5rs-root (%r7rs-find-r5rs %r7rs-r5rs-candidates))
(if (null? %r7rs-r5rs-root)
  (do
    (display "x-r7rs: cannot find the x-r5rs bundle it extends -- no")
    (newline)
    (display "r5rs/base.x under any of:")
    (newline)
    (def %r7rs-say-r5rs
      (fn (self roots)
        (if (null? roots)
          ()
          (do
            (display "  ")
            (display (%path-join (first roots) "r5rs/base.x"))
            (newline)
            (self (rest roots))))))
    (%r7rs-say-r5rs %r7rs-r5rs-candidates)
    (Sys exit 1))
  ())
(import-path! %r7rs-r5rs-root)

(import r5rs/base)
(import r7rs/base)

(set! %repl-prompt "> ")
(set! %lang-name "R7RS Scheme")
(set! %lang-version r7rs-version)
; Scheme prints Scheme results: (b c), not x's round-trippable ('b 'c).
; See the r5rs bundle's printer.x for why that is a re-meaning rather than a workaround.
(set! %repl-print %r7rs-repl-print)

; Batch (-f) means stdin holds a Scheme program, not a session: the REPL's
; fd swap would discard it unread.  %batch? comes from x-core via banner.x.
(unless %batch? (do (%banner) (repl)))
