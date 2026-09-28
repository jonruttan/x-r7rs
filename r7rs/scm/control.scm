; --- Control extensions (R7RS §4.2.2) ---

; let-values: destructure multiple-value returns
; (let-values (((a b) (values 1 2))) body ...)
;
; The formals are bound in a child of the caller's environment. An
; environment is a pair of bindings and a parent, so (cons () env) is a new,
; empty child, and each formal is a `def` evaluated in it. The rest of the
; bindings and the body then evaluate in that child.
(define let-values
  (op (bindings . body)
    env
    (if (null? bindings)
      (eval (cons (lit begin) body) env)
      (let ((binding (car bindings))
            (rest-bindings (cdr bindings)))
        (let ((formals (car binding))
              (producer (cadr binding)))
          (call-with-values
            (lambda () (eval producer env))
            (lambda vals
              (let ((child (cons () env)))
                (let loop ((fs formals) (vs vals))
                  (cond
                    ((null? fs) #t)
                    ((symbol? fs)
                     ; rest-arg: bind remaining values as list
                     (eval (list (lit def) fs (list (lit lit) vs)) child))
                    (#t
                     (begin
                       (eval
                         (list (lit def) (car fs) (list (lit lit) (car vs)))
                         child)
                       (loop (cdr fs) (cdr vs))))))
                (eval
                  (list (lit let-values) rest-bindings
                    (cons (lit begin) body))
                  child)))))))))

; let*-values: like let-values but sequential
(define let*-values
  (op (bindings . body)
    env
    (if (null? bindings)
      (eval (cons (lit begin) body) env)
      (eval
        (list (lit let-values) (list (car bindings))
          (cons (lit let*-values) (cons (cdr bindings) body)))
        env))))
