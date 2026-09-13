; # x-r7rs -- R7RS Scheme on x-lang
;
; ## run.x -- the entry point
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
; This file contains no path literals, its dependency included. x.sh boots the
; dialect lang.xon declares, arms the root of every lang the manifest requires,
; arms this bundle's own root last, cats this file, and appends the launcher
; when no -f was given, so both imports below resolve wherever the bundles sit.
; (requires-lang "r5rs") in lang.xon is what makes a missing dependency a
; startup refusal rather than a run-time surprise.
(import r5rs/base)
(import r7rs/base)

(set! %lang-name "R7RS Scheme")
(set! %lang-version r7rs-version)
(set! %repl-prompt "> ")
; Scheme results, not x's round-trippable ones -- see the r5rs bundle's
; printer.x, which this one re-exports.
(set! %repl-print %r7rs-repl-print)
