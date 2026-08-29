; # x-r7rs -- R7RS Scheme on x-lang
;
; ## r7rs/base.x -- the language, assembled
;
; @author [Jon Ruttan](jonruttan@gmail.com)
; @copyright 2026 Jon Ruttan
; @license MIT No Attribution (MIT-0)
;
; R7RS IS R5RS PLUS, and this file is only the plus.  run.x arms the x-r5rs
; bundle's root and imports r5rs/base before this loads, so everything under
; ./scm/ here can be written as if the R5RS library were the standard library
; -- which, for R7RS, it is.
;
; That dependency is the first of its kind among these bundles, and the
; contract has no vocabulary for it: personality.xon carries name, dialect,
; release and entry, and nothing says "and it needs x-r5rs at some version".
; The probe lives in run.x, which is the one file allowed to know where things
; are; x-lang#526 asks for the manifest row that would replace it.
;
; No path literals and no dialect boot here: run.x owns both.  Siblings are
; reached by ./-relative include-once, which resolves against THIS file.

(import r7rs/printer)

(provide r7rs/base r7rs-version %r7rs-repl-print)

(def r7rs-version "0.1.0")

; R7RS results print like R5RS results -- symbols bare, strings quoted.  The
; writer is the r5rs bundle's, already installed as `write` by r5rs/base.x;
; this bundle re-exports the repl hook under its own name so run.x has one
; spelling to set.  (Three bundles have now needed the same twenty lines --
; x-lang#518.)
(def %r7rs-repl-print %r5rs-repl-print)

; --- x-lang native constructs ------------------------------------------------
(include-once "./x/case-lambda.x")
(include-once "./x/promises.x")
(include-once "./x/records.x")
(include-once "./x/params.x")
(include-once "./x/cond-expand.x")
; LOADED AGAIN, as of x-lang#527.  R7RS `guard` and x's `guard` are different
; forms with the same name, so providing one means shadowing the other -- and
; shadowing interposes a call frame between the runner's %seq and the body it
; guards.  Every `define` inside a guarded body used to bind nowhere, silently,
; because define bound by letting TCO pop the operative's frame.
;
; r5rs/aliases.x's define now goes through (base def-global), which takes the
; global path whatever the frame depth, so the frame this file adds costs
; nothing.
; ./x/guard.x is NOT loaded -- see the note in that file
; ./x/bytevector.x is NOT loaded -- see the note at the top of that file.

; --- Scheme standard library -------------------------------------------------
(include-once "./scm/equiv.scm")
(include-once "./scm/numeric.scm")
(include-once "./scm/char.scm")
(include-once "./scm/string.scm")
(include-once "./scm/list.scm")
(include-once "./scm/vector.scm")
(include-once "./scm/error.scm")
(include-once "./scm/control.scm")
; ./scm/ports.scm is NOT loaded: it extends the R5RS port layer, which the
; x-r5rs bundle also defers.  Both come back together or not at all.
