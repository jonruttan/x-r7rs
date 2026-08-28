; --- Records (R7RS §5.5) ---
;
; EVERY GENERATED PROCEDURE IS A `lambda`, NOT AN `fn`, and that is the whole
; of the port.  The 2024 file emitted (fn (x) ...) for the predicate and each
; accessor, and (fn <field-names> ...) for the constructor.  x's `fn` takes an
; explicit receiver, so each of those bound its FIRST REAL PARAMETER to the
; receiver and shifted the rest off the end -- the constructor built a record
; from nothing and the accessors read a slot that was not there, which
; segfaults rather than raising.
;
; r5rs/aliases.x's `lambda` is the operative that splices the receiver in, so
; emitting `lambda` makes the generated code correct by construction and keeps
; this file readable as Scheme.  Same reasoning, same fix, as every other
; (fn (...)) in these bundles.


(define
  define-record-type
  (op (name constructor-spec pred . field-specs)
    env
    (eval
      (cons
        (lit begin)
        (append
          (list
            (list
              (lit %def-global)
              (list (lit quote) name)
              (list
                (lit make-type)
                (list (lit quote) name)
                (list
                  (lit list)
                  (list
                    (lit pair)
                    (list (lit quote) (lit write))
                    (list
                      (lit lambda)
                      (list (lit self))
                      (list
                        (lit display)
                        (string-append "#<" (convert name %string) ">")))))))
            (list
              (lit %def-global)
              (list (lit quote) (car constructor-spec))
              (list
                (lit lambda)
                (cdr constructor-spec)
                (list
                  (lit make-instance)
                  name
                  (cons
                    (lit list)
                    (map
                      (lambda (f) (list (lit pair) (list (lit quote) f) f))
                      (cdr constructor-spec))))))
            (list
              (lit %def-global)
              (list (lit quote) pred)
              (list
                (lit lambda)
                (list (lit x))
                (list (lit type?) (lit x) name))))
          (append
            (map
              (lambda
                (spec)
                (list
                  (lit %def-global)
                  (list (lit quote) (list-ref spec 1))
                  (list
                    (lit lambda)
                    (list (lit x))
                    (list
                      (lit cdr)
                      (list
                        (lit assq)
                        (list (lit quote) (car spec))
                        (list (lit first) (lit x)))))))
              field-specs)
            (list (list (lit quote) name))))))))
