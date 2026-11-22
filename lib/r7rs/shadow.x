; r7rs/shadow.x -- the names R7RS shadows over R5RS, put down for an image
; write and back up after a load.
;
; guard shadows the platform's guard with R7RS's; the rows record how to
; restore and reshadow each, and the image hooks run them.  Its own module,
; because guard.x registers a row while base.x is still loading and an
; import of base from there would find nothing provided yet.

(module r7rs/shadow)
(def %shadow-rows ())          ; ((restore . reshadow) ...), newest first
(def r7rs-shadow!
  (fn (_ restore reshadow)
    (set! %shadow-rows (pair (pair restore reshadow) %shadow-rows))))
;  BEGIN, NOT do, AND THE REASON IS THIS BUNDLE'S OWN.  r5rs/scm/derived.scm
; re-means `do` as R5RS iteration and tells sequencing apart by structural pattern: a first
; argument whose every element is a pair reads as a binding list.  Calling a
; thunk fetched from a row -- ((first (first l))) -- is exactly that pattern, so
; (do ((first (first l))) (self (rest l))) bound `first`, tested `self`, and
; returned quietly having called NOTHING.  Measured: the restore thunk ran on
; every row and the image still came back `unnameable: 2`.  x/guard.x names this
; very form as the heuristic's known hole and says no such form exists in this
; bundle; it did, here.  `begin` is r5rs/aliases.x's capture of x's own
; sequencing operative, taken before derived.scm rebinds the name, so it cannot
; be re-read.
(def r7rs-shadows-down!
  (fn (_)
    ((fn (self l)
       (if (null? l) ()
         (begin ((first (first l))) (self (rest l)))))
     %shadow-rows)))
(def r7rs-shadows-up!
  (fn (_)
    ((fn (self l)
       (if (null? l) ()
         (begin ((rest (first l))) (self (rest l)))))
     %shadow-rows)))
; GUARDED, because a platform older than the image tools binds neither list --
; and `guard` is still x's own here, three includes ahead of x/guard.x.
(guard (_ ())
  (begin (set! %image-transients (pair r7rs-shadows-down! %image-transients))
         (set! %image-recache-hooks (pair r7rs-shadows-up! %image-recache-hooks))))

; r7rs-shadow! is global: scm/error.scm registers a row too, and an included
; file runs in the root.
(provide r7rs/shadow (global r7rs-shadow!) r7rs-shadows-down! r7rs-shadows-up!)
