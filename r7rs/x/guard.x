; --- R7RS guard (§4.2.7) ---
;
; (guard (var clause ...) body ...) where each clause is (test expr ...) or
; (else expr ...) -- cond clauses, evaluated with the raised object bound to
; var.
;
; DISPATCHED, NOT SHADOWED, for the reason x-lang#525 describes about `do`:
; `guard` is a name the platform resolves BY NAME at run time, and one of its
; callers is the spec runner's own error handler --
;
;   (guard (err (display "Error: ") (display err) (newline))
;     (%repl-print (eval! %r)))
;
; -- which is x's shape, not R7RS's: a sequence of handler FORMS, not a list of
; cond clauses.  Shadow the name with an R7RS-only transform and that handler
; becomes (cond (display "Error: ") ...), which is not what anyone wrote.
;
; The two shapes are distinguishable where it matters.  R7RS clauses are all
; pairs; an x handler sequence that is also all pairs behaves identically under
; either reading only if its first form's head is truthy -- which for
; (display ...) it is.  So the test below is necessary but not sufficient, and
; the escape hatch is that anything with a non-pair among the handler forms
; passes straight through untouched.
;
; AND IT IS STILL NOT ENOUGH, WHICH IS WHY r7rs/base.x DOES NOT LOAD THIS FILE.
; Shadowing `guard` at all -- however faithfully it dispatches -- interposes one
; operative frame between the runner's %seq and the body it guards, and
; `define` cannot survive that.  r5rs/aliases.x binds by letting TCO pop the
; operative's frame so the def lands globally; x offers no way to define in a
; caller's environment across a frame boundary (x-lang#527, measured).  So
; every define inside a guarded body binds nowhere, silently, and the runner's
; own handler swallows the unbound-symbol error it caused: ~100 spec failures
; with empty output, to buy the 17 in 12-exceptions.spec.md.
;
; The module is kept because it is correct and because the day x-lang#527 lands
; it becomes loadable as it stands.  Dropping `let` from the first version of
; this file was necessary but not sufficient -- worth knowing, because the let
; removal LOOKED like the fix and the numbers barely moved.

(define %c-guard guard)

; THE DISCRIMINATOR IS THE CLAUSE HEAD, not merely "is it a pair".
;
; Both shapes are lists of pairs, so "all pairs" does not separate them -- and
; getting that wrong is worse than not dispatching at all, because the runner's
; own error handler
;
;   (err (display "Error: ") (display err) (newline))
;
; then becomes (cond (display "Error: ") ...), whose first clause tests the
; VALUE of `display` -- truthy -- and returns the string without printing it.
; Every error in the suite is swallowed and 55 tests report empty output.
;
; An R7RS clause leads with a TEST: `else`, `#t`, or a predicate CALL, which is
; a pair.  An x handler form leads with the operator of a statement -- a bare
; symbol like display or newline.  So: every head must be `else`, `#t`, or a
; pair.  Anything else is x's shape and passes through untouched.
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

(define
  guard
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
