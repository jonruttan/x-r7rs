; # x-r7rs -- R7RS Scheme on x-lang
;
; ## run.x -- THE entry
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
; THIS FILE KNOWS NO PATHS, its dependency included.  x.sh boots the dialect
; lang.xon declares, arms the root of every lang the manifest requires, arms
; this bundle's own root last, cats this file, and appends the launcher when no
; -f was given.  So both imports below resolve wherever the bundles happen to
; sit, and neither this file nor the harness has to find anything.
;
; It used to carry the search itself -- derive its own root from the armed
; import path, probe beside it for r5rs/ and x-r5rs/, and refuse with a message
; nobody would see until run time.  (requires-lang "r5rs") replaced all of it,
; and moved the refusal to startup where a missing dependency belongs.
(import r5rs/base)
(import r7rs/base)

(set! %lang-name "R7RS Scheme")
(set! %lang-version r7rs-version)
(set! %repl-prompt "> ")
; Scheme results, not x's round-trippable ones -- see the r5rs bundle's
; printer.x, which this one re-exports.
(set! %repl-print %r7rs-repl-print)
