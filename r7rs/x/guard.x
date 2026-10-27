; --- R7RS guard (4.2.7) ---
;
; (guard (var clause ...) body ...) where each clause is (test expr ...) or
; (else expr ...) -- cond clauses, evaluated with the raised object bound to
; var.
;
; Dispatched, not shadowed, for the reason x-lang#525 describes about `do`:
; `guard` is a name the platform resolves by name at run time, and one of its
; callers is the spec runner's own error handler, which is x's pattern
; (a sequence of handler forms) not R7RS's (a list of cond clauses). Shadowing the
; name with an R7RS-only transform would misread that handler.
;
; Shadowing `guard` interposes one operative frame between the caller and the
; guarded body. `define` binds in the root whatever the frame depth (engine
; law 10), so a `define` inside the guarded body still binds.

(module r7rs/x/guard)
(import r7rs/shadow r7rs-shadow!)
(define %c-guard guard)

; The discriminator is the clause head, not merely "is it a pair": both patterns
; are lists of pairs. An R7RS clause leads with a test -- `else`, `#t`, or a
; predicate call (a pair). An x handler form leads with the operator of a
; statement -- a bare symbol like display or newline. So every head must be
; `else`, `#t`, or a pair; anything else is x's pattern and passes through
; untouched. Getting this wrong turns the runner's own handler into a `cond`
; whose first clause tests the value of `display` and swallows the error.
(define
  %r7rs-guard-head-test?
  (lambda (c)
    (if (pair? (car c)) #t
      (if (eq? (car c) (lit else)) #t
        (eq? (car c) #t)))))

(define
  %r7rs-guard-clauses?
  (lambda (cs)
    (if (null? cs) #f (%r7rs-guard-all-tests? cs))))

(define
  %r7rs-guard-all-tests?
  (lambda (cs)
    (if (null? cs) #t
      (if (pair? (car cs))
        (if (%r7rs-guard-head-test? (car cs))
          (%r7rs-guard-all-tests? (cdr cs))
          #f)
        #f))))

; NAMED, then installed.  The op is a global of its own so that the state
; image table in r7rs/base.x has something to put BACK: its restore thunk
; hands `guard` to the platform primitive for the write -- the only form in
; which the image can name it -- and its reshadow thunk hands it to this.
(define
  %r7rs-guard
  (op (clause . body)
    env
    (eval
      (cons (lit %c-guard)
        (cons
          (if (%r7rs-guard-clauses? (cdr clause))
            ; R7RS: the handler is a cond over the clauses.
            (list (car clause) (cons (lit cond) (cdr clause)))
            ; x: the handler forms are already the handler.
            clause)
          body))
      env)))
(define guard %r7rs-guard)
; Through %r7rs-def-root, not set!: `guard` is bound twice -- bare by C in the
; base spine, and here in the global tree -- and from inside a frame a set!
; answers ok while a later read still sees the old value. %r7rs-def-root
; (r7rs/base.x) binds in the root whatever the frame depth. %c-guard is nilled
; for the write and re-captured on load, the same way and for the same reason
; as %c-error (scm/error.scm): the primitive travels under its own name, which
; the loader restores.
(r7rs-shadow!
  (lambda () (begin (%r7rs-def-root (lit guard) %c-guard)
                    (%r7rs-def-root (lit %c-guard) ())))
  (lambda () (begin (%r7rs-def-root (lit %c-guard) guard)
                    (%r7rs-def-root (lit guard) %r7rs-guard))))
