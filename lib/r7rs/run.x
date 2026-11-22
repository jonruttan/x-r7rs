; # x-r7rs -- R7RS Scheme on x-lang
;
; ## r7rs/run -- the entry
;
; @description R7RS-small as a thin layer over x-r5rs: case-lambda, records,
;   parameters, promises, cond-expand, and the R7RS library additions.
; @author [Jon Ruttan](jonruttan@gmail.com)
; @copyright 2026 Jon Ruttan
; @license MIT No Attribution (MIT-0)
;
; Usage:
;   x -l r7rs               interactive
;   x -l r7rs -f prog.scm   batch
;
; The wrapper boots the dialect bundle.xon declares, arms the lib/ of every
; bundle the manifest requires, arms this bundle's lib/ last, imports this
; module, and calls its `main`. (requires-bundle "r5rs") in bundle.xon is what
; makes a missing dependency a startup refusal rather than a run-time
; surprise. Importing this module sets Scheme up and starts nothing; what
; follows on the stream -- a program, or the launcher's session -- is read
; with Scheme's names in place.
(module r7rs/run)
(import r5rs/base)
(import r7rs/base r7rs-version r7rs-repl-print)

(set! %lang-name "R7RS Scheme")
(set! %lang-version r7rs-version)
(set! %repl-prompt "> ")
; Scheme results, not x's round-trippable ones -- see the r5rs bundle's
; printer.x, which this one re-exports.
(set! %repl-print r7rs-repl-print)

; Nothing to start: a program is read by the platform's loop, in Scheme's
; vocabulary, and a session by the launcher's.
(def main (fn (_) ()))

(provide r7rs/run main)
