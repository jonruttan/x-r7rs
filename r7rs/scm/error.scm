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
;  AND %c-error IS NILLED FOR THE WRITE, not carried.  Measured: an image that
; carries this reference brings it back as "" -- the writer names an off-chain
; primitive found at a type-struct row as a TYPE-STATIC and resolves it to that
; row in the loading base, which for %c-error is a string.  The SAME primitive
; reached through its own global comes back as #<prim>, so the restored name is
; the door, and the hook re-captures through it.
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
