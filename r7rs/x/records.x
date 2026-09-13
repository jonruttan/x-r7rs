; --- Records (R7RS 5.5) ---
;
; Every generated procedure is a `lambda`, not an `fn`. x's `fn` takes an
; explicit receiver, so `fn`-shaped Scheme formals would bind the first real
; parameter to the receiver and shift the rest off the end -- the constructor
; would build a record from nothing and an accessor read a slot that is not
; there. r5rs/aliases.x's `lambda` is the operative that splices the receiver
; in, so emitting `lambda` makes the generated code correct by construction and
; reads as Scheme.


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
