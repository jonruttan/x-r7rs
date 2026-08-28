; # x-r7rs -- R7RS Scheme on x-lang
;
; ## r7rs/printer.x -- a pointer, not a printer
;
; @author [Jon Ruttan](jonruttan@gmail.com)
; @copyright 2026 Jon Ruttan
; @license MIT No Attribution (MIT-0)
;
; R7RS's `write` is R5RS's `write`, so there is nothing to re-mean here: the
; x-r5rs bundle already rebound it, and run.x imports r5rs/base first.  This
; module exists only so r7rs/base.x has a name to re-export, and so that the
; day R7RS's datum labels (#0=, #0#) need a writer of their own, there is an
; obvious place to put it.

(provide r7rs/printer)
