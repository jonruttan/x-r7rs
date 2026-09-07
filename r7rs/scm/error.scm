; --- Error objects (R7RS §6.11) ---
; Error objects are tagged lists: (%error-object message irritants)

(define %error-tag (cons (lit %error) (lit object)))

; NAMED, then installed -- the shape r7rs/base.x's shadow table needs.  `error`
; is bare C syntax with no catalog entry, so a state image can name it only
; under its own global; the restore thunk hands the name back for the write and
; the reshadow thunk puts this one up again after the load.
(define %c-error error)
(define %r7rs-error
  (lambda (message . irritants)
    (%c-error (list %error-tag message irritants))))
(define error %r7rs-error)
; Through %def-global, not set!: see the note in x/guard.x -- a name bound both
; bare by C and in the global tree does not take a set! from inside a frame.
;  AND %c-error IS NILLED FOR THE WRITE, not carried, so that NO reference to a
; bare C primitive has to survive the image at all -- only the name does, and
; the loader restores that against its own base.  It is float.x's transient
; discipline, and it is the reason rather than the history below.
;   THE HISTORY, because the comment that stood here overstated it.  On x-lang
; cc8c53c0 an image that carried this reference brought it back as "" while the
; same primitive reached through its own global came back as #<prim>, and the
; note here called that a writer defect in the type-static naming.  It does NOT
; reproduce on f0ff111c: carrying the reference round-trips fine, checked both
; by this bundle and by a bare capture in a lib of its own.  So do not go
; hunting that defect on a current platform -- either it was fixed among
; #641-#643 or it needed the in-flight writer that tree was carrying.  What is
; kept is the weaker dependency, not the diagnosis.
(%r7rs-shadow!
  (lambda () (begin (%def-global (lit error) %c-error)
                    (%def-global (lit %c-error) ())))
  (lambda () (begin (%def-global (lit %c-error) error)
                    (%def-global (lit error) %r7rs-error))))

(define (error-object? obj)
  (and (pair? obj) (eq? (car obj) %error-tag)))

(define (error-object-message obj)
  (if (error-object? obj) (cadr obj) obj))

(define (error-object-irritants obj)
  (if (error-object? obj) (caddr obj) ()))
