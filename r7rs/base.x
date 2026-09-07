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

; --- What this bundle shadows, and the state image ---------------------------
;
; `guard` and `error` are C CONTROL-FLOW SYNTAX BOUND BARE -- (guard spine)
; and (error spine) in the engine's ISA contract (engine/tools/contract/isa.x),
; "bound bare by C, no catalog entry".  A state image can therefore name such a
; primitive ONE way only: under the global the engine bound it to.  The writer
; looks each %isa-bare name up in the base it is imaging and takes the value's
; function pointer (tools/dev/image-name.x), and that file already states the
; failure -- "a name the library has rebound yields the wrapper, not the
; primitive, and is simply not added".
;
; This bundle rebinds BOTH, keeping the originals in %c-guard (x/guard.x) and
; %c-error (scm/error.scm).  So the writer could name neither address and
; refused the spec harness outright:
;
;   objects: 144820  externals: 249  roots: 19  unnameable: 2
;     ("PRIMITIVE" 'foreign-unnamed 4378148428)   ; %c-guard
;     ("PRIMITIVE" 'foreign-unnamed 4378149528)   ; %c-error
;
; THE SHADOW IS PUT DOWN BEFORE THE WRITE AND PICKED UP AFTER THE LOAD.  That
; is the SECOND of docs/state-images.md's two transient shapes -- the one
; tower-compiled.x uses for its compiled analysers -- and not float.x's
; nil-and-re-derive, for a reason particular to bare syntax: once its name is
; taken there is NO other door to the primitive, so a hook that ran after the
; load would have nothing to re-derive it FROM.  The image has to carry the
; primitive itself, under its own name.
;
; The transient thunk runs in the writer's child before the walk and puts the
; platform binding back, which makes the address nameable again; it costs the
; image nothing, because the replacement stays reachable from the table below.
; The loader resolves that name against its OWN base, before the install, so
; the pointer it restores is this process's.  The recache hook then puts the
; shadow back once the loader is done.
;
; Each shadow REGISTERS ITSELF on the line that installs it, so the table can
; never disagree with what was actually rebound -- x/guard.x installs its one
; conditionally, and an engine that does not get the shadow must not get the
; hook either.
(def %r7rs-shadow-rows ())          ; ((restore . reshadow) ...), newest first
(def %r7rs-shadow!
  (fn (_ restore reshadow)
    (set! %r7rs-shadow-rows (pair (pair restore reshadow) %r7rs-shadow-rows))))
;  BEGIN, NOT do, AND THE REASON IS THIS BUNDLE'S OWN.  r5rs/scm/derived.scm
; re-means `do` as R5RS iteration and tells sequencing apart by SHAPE: a first
; argument whose every element is a pair reads as a binding list.  Calling a
; thunk fetched from a row -- ((first (first l))) -- is exactly that shape, so
; (do ((first (first l))) (self (rest l))) bound `first`, tested `self`, and
; returned quietly having called NOTHING.  Measured: the restore thunk ran on
; every row and the image still came back `unnameable: 2`.  x/guard.x names this
; very form as the heuristic's known hole and says no such form exists in this
; bundle; it did, here.  `begin` is r5rs/aliases.x's capture of x's own
; sequencing operative, taken before derived.scm rebinds the name, so it cannot
; be re-read.
(def %r7rs-shadows-down!
  (fn (_)
    ((fn (self l)
       (if (null? l) ()
         (begin ((first (first l))) (self (rest l)))))
     %r7rs-shadow-rows)))
(def %r7rs-shadows-up!
  (fn (_)
    ((fn (self l)
       (if (null? l) ()
         (begin ((rest (first l))) (self (rest l)))))
     %r7rs-shadow-rows)))
; GUARDED, because a platform older than the image tools binds neither list --
; and `guard` is still x's own here, three includes ahead of x/guard.x.
(guard (_ ())
  (begin (set! %image-transients (pair %r7rs-shadows-down! %image-transients))
         (set! %image-recache-hooks (pair %r7rs-shadows-up! %image-recache-hooks))))

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
