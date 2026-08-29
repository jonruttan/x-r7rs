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
; x.sh boots the dialect lang.xon declares, arms this bundle's root with
; import-path!, cats this file, and appends the launcher when no -f was given.
; So `import r7rs/base` resolves against the bundle wherever it happens to sit,
; and this file needs no idea where that is.
;
; --- THE ONE THING IT STILL HAS TO FIND -----------------------------------
;
; R7RS is R5RS plus about 700 lines, and this bundle does not work without the
; x-r5rs one.  lang.xon has no row for that -- there is no
; (requires-lang "x-r5rs" "v0.6.0") -- so x.sh arms THIS bundle's root and
; nothing else, and the sibling has to be found here.  x-lang#526 asks for the
; row that would delete every line below.
;
; The bundle's own root is the one x.sh just armed, so the sibling is beside
; it.  Two spellings are probed because two layouts are both real: an installed
; tree names the directory after the lang (langs/r5rs), a development checkout
; after the repository (languages/x-r5rs).  Neither is a literal reaching into
; the platform -- they are this bundle's neighbours.
(def %r7rs-own-root (first (first %import-roots-cell)))
(def %r7rs-sibling
  (fn (self names)
    (if (null? names)
      ()
      (let ((%c (%path-join (%path-join %r7rs-own-root "..") (first names))))
        (if (Sys file-exists? (%path-join %c "lang.xon"))
          %c
          (self (rest names)))))))
(def %r7rs-r5rs-root (%r7rs-sibling (list "r5rs" "x-r5rs")))

(if (null? %r7rs-r5rs-root)
  (do
    (display "x-r7rs: cannot find the x-r5rs lang it extends.")
    (newline)
    (display "  looked beside ")
    (display %r7rs-own-root)
    (display " for r5rs/ and x-r5rs/")
    (newline)
    (display "  install it too:  make install  in the x-r5rs tree")
    (newline)
    (Sys exit 1))
  ())
(import-path! %r7rs-r5rs-root)

(import r5rs/base)
(import r7rs/base)

(set! %lang-name "R7RS Scheme")
(set! %lang-version r7rs-version)
(set! %repl-prompt "> ")
; Scheme results, not x's round-trippable ones -- see the r5rs bundle's
; printer.x, which this one re-exports.
(set! %repl-print %r7rs-repl-print)
