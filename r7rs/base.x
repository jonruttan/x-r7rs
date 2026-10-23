; # x-r7rs -- R7RS Scheme on x-lang
;
; ## r7rs/base.x -- the language, assembled
;
; @author [Jon Ruttan](jonruttan@gmail.com)
; @copyright 2026 Jon Ruttan
; @license MIT No Attribution (MIT-0)
;
; R7RS is R5RS plus, and this file is only the plus. run.x arms the x-r5rs
; bundle's root and imports r5rs/base before this loads, so everything under
; ./scm/ can be written as if the R5RS library were the standard library --
; which, for R7RS, it is. The dependency is declared by (requires-lang "r5rs")
; in lang.xon.
;
; No path literals and no dialect boot here: run.x owns both. Siblings are
; reached by ./-relative include-once, which resolves against this file.

(module r7rs/base)
(import r7rs/printer)
(import r5rs/printer r5rs-repl-print)
(import r7rs/shadow r7rs-shadows-down! r7rs-shadows-up!)

(def r7rs-version "0.1.0")

; R7RS results print like R5RS results -- symbols bare, strings quoted.  The
; writer is the r5rs bundle's, already installed as `write` by r5rs/base.x;
; this bundle re-exports the repl hook under its own name so run.x has one
; spelling to set.  (Three bundles have now needed the same twenty lines --
; x-lang#518.)
(def r7rs-repl-print r5rs-repl-print)

; --- What this bundle shadows, and the state image ---------------------------
;
; `guard` and `error` are C control-flow syntax bound bare -- (guard spine) and
; (error spine) in the engine's ISA contract, with no catalog entry. A state
; image can name such a primitive only one way: under the global the engine
; bound it to. This bundle rebinds both (keeping the originals in %c-guard,
; x/guard.x, and %c-error, scm/error.scm), so the writer could name neither
; address and would refuse the image.
;
; So the shadow is put down before the write and picked up after the load --
; the transient pattern tower-compiled.x uses, not float.x's nil-and-re-derive:
; once a bare primitive's name is taken there is no other door to re-derive it
; from, so the image has to carry the primitive under its own name. A transient
; thunk in the writer's child puts the platform binding back before the walk,
; making the address nameable; the loader resolves that name against its own
; base, and a recache hook puts the shadow back once the load is done.
;
; Each shadow registers itself on the line that installs it, so the table
; cannot disagree with what was rebound. x/guard.x installs its one
; conditionally, and an engine that does not get the shadow must not get the
; hook either.

; --- x-lang native constructs ------------------------------------------------
(include-once "./x/case-lambda.x")
(include-once "./x/promises.x")
(include-once "./x/records.x")
(include-once "./x/params.x")
(include-once "./x/cond-expand.x")
; R7RS `guard` and x's `guard` are different forms with the same name, so
; providing one shadows the other, which interposes a call frame between the
; runner's %seq and the body it guards. r5rs/aliases.x's define goes through
; (base def-global), which takes the global path whatever the frame depth, so
; a `define` inside a guarded body still binds.
(include-once "./x/guard.x")
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
; ./scm/ports.scm EXTENDS the R5RS port layer, which x-r5rs now loads -- the
; note here said both were deferred together, and that stopped being true when
; that bundle rewrote its ports onto the platform's File.  What this adds is
; string ports, built on that layer's polymorphic source.
(include-once "./scm/ports.scm")

(provide r7rs/base r7rs-version r7rs-repl-print)
