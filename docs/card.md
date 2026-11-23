# x-r7rs card

## Run

```sh
x -l r7rs
x -l r7rs -f PROGRAM.scm
x -l r7rs -f tests/card/point.scm -> 5
```

```r7rs
(define-record-type point (make-point x y) point? (x point-x) (y point-y))
(define (dist p) (exact (sqrt (+ (square (point-x p)) (square (point-y p))))))
(display (dist (make-point 3 4)))       ; -> 5
(newline)
```

| Run                   | Is                                                |
|-----------------------|---------------------------------------------------|
| `x -l r7rs`           | the prompt: each form's value is printed          |
| `x -l r7rs -f FILE`   | a program in a file: only what it writes is printed |
| this page             | what R7RS adds; the x-r5rs card has the rest      |

## Records

| Form                                        | Does                         |
|---------------------------------------------|------------------------------|
| `(define-record-type T (MAKE F ...) T? (F GET) ...)` | a record type        |
| `(MAKE V ...)`                              | a new record                 |
| `(T? X)`                                    | whether X is one             |
| `(GET R)`                                   | a field's value              |

```r7rs
(define-record-type point (make-point x y) point? (x point-x) (y point-y))
(define p (make-point 3 4))
(display (point-x p)) (display " ") (display (point-y p)) (newline) ; -> 3 4
(display (point? p)) (display (point? 5)) (newline)     ; -> #t#f
(write p) (newline)                                     ; -> #<point>
```

## Procedures and binding

| Form                                     | Does                            |
|------------------------------------------|---------------------------------|
| `(case-lambda ((ARG ...) BODY ...) ...)` | picks a clause by argument count |
| `(when TEST FORM ...)`                   | the forms when TEST holds       |
| `(unless TEST FORM ...)`                 | the forms when TEST does not    |
| `(let-values (((A B) EXPR)) BODY ...)`   | names for the values EXPR gives |
| `(let*-values (((A) E1) ((B) E2)) BODY ...)` | each sees the names before it |

```r7rs
(define area (case-lambda ((r) (* 3 r r)) ((w h) (* w h))))
(display (area 2)) (display " ") (display (area 2 3)) (newline) ; -> 12 6
(when (> 3 2) (display "when")) (newline)               ; -> when
(unless (< 3 2) (display "unless")) (newline)           ; -> unless
(let-values (((root rest) (exact-integer-sqrt 17)))
  (display (list root rest)))
(newline)                                               ; -> (4 1)
(let*-values (((a b) (values 1 2)) ((c) (values (+ a b))))
  (display c))
(newline)                                               ; -> 3
```

## Parameters

| Form                                   | Does                              |
|----------------------------------------|-----------------------------------|
| `(make-parameter V)`                   | a parameter: `(P)` is its value   |
| `(make-parameter V CONVERT)`           | each value passed through CONVERT |
| `(parameterize ((P V) ...) BODY ...)`  | P is V for the body only          |

```r7rs
(define radix (make-parameter 10))
(display (radix)) (display " ")
(parameterize ((radix 2)) (display (radix)) (display " "))
(display (radix)) (newline)                             ; -> 10 2 10
(define width (make-parameter 5 (lambda (x) (* x 2))))
(display (width)) (display " ")
(parameterize ((width 4)) (display (width)))
(newline)                                               ; -> 10 8
```

## Errors

| Form                                    | Does                             |
|-----------------------------------------|----------------------------------|
| `(error MESSAGE IRRITANT ...)`          | raises an error object           |
| `(raise OBJ)`                           | raises OBJ as it is              |
| `(guard (E CLAUSE ...) BODY ...)`       | BODY; on a raise, a CLAUSE for E |
| `(error-object? X)`                     | whether X came from `error`      |
| `(error-object-message E)`              | its message                      |
| `(error-object-irritants E)`            | its irritants, a list            |

```r7rs
(display (guard (e (#t (list (error-object-message e)
                             (error-object-irritants e))))
           (error "bad thing" 1 2)))
(newline)                                               ; -> (bad thing (1 2))
(display (guard (e ((symbol? e) (list 'sym e))) (raise 'oops)))
(newline)                                               ; -> (sym oops)
(display (guard (e ((string? e) 'str) ((number? e) (* e 2))) (raise 21)))
(newline)                                               ; -> 42
(display (guard (e ((error-object? e) 'err)) (+ 1 2)))
(newline)                                               ; -> 3
```

## Promises

| Form                     | Does                                          |
|--------------------------|-----------------------------------------------|
| `(delay EXPR)`           | a promise: EXPR is worked out once, when forced |
| `(delay-force EXPR)`     | a promise of what the promise EXPR gives      |
| `(make-promise V)`       | a promise already holding V                   |
| `(force P)`              | its value                                     |
| `(promise? X)`           | whether X is one                              |

```r7rs
(define pr (delay (begin (display "once ") 7)))
(display (force pr)) (display (force pr)) (newline)     ; -> once 77
(display (force (make-promise 5))) (display (promise? pr)) (newline) ; -> 5#t
(display (force (delay-force (delay 9)))) (newline)     ; -> 9
```

## Features

| Form                                     | Gives                         |
|------------------------------------------|-------------------------------|
| `(cond-expand (FEATURE FORM ...) ...)`   | the first clause that holds   |
| `(else FORM ...)`                        | the last clause, when none do |
| `(and F ...)` `(or F ...)` `(not F)`     | combined feature tests        |
| `r7rs` `x-lang` `ieee-float`             | the features that hold here   |

```r7rs
(display (cond-expand (r7rs 'r7rs) (else 'other))) (newline)        ; -> r7rs
(display (cond-expand ((and r7rs (not foo)) 'yes) (else 'no)))
(newline)                                               ; -> yes
```

## Strings, vectors, lists

| Procedure                            | Gives                             |
|--------------------------------------|-----------------------------------|
| `(string-map PROC S)`                | PROC on each character            |
| `(string-for-each PROC S)`           | PROC called on each character     |
| `(vector-map PROC V ...)`            | PROC on each element              |
| `(vector-for-each PROC V)`           | PROC called on each element       |
| `(vector-append V ...)`              | the vectors joined                |
| `(string->vector S)` `(vector->string V)` | between strings and vectors  |
| `(list-copy L)`                      | a new list, the same elements     |
| `(make-list N FILL)`                 | N elements of FILL                |
| `(string-ci=? A B)` `(char-foldcase C)` | case left out                  |
| `(digit-value C)`                    | 0 to 9 for a digit, else `#f`     |

```r7rs
(display (string-map char-upcase "abc")) (newline)      ; -> ABC
(string-for-each (lambda (c) (display " ") (display (char->integer c))) "ab")
(newline)                                               ; ->  97 98
(display (vector-map (lambda (x) (* x x)) #(1 2 3))) (newline) ; -> #(1 4 9)
(vector-for-each (lambda (x) (display x)) #(1 2 3)) (newline) ; -> 123
(display (vector-append #(1) #(2 3))) (newline)         ; -> #(1 2 3)
(write (string->vector "ab")) (write (vector->string #(#\x #\y))) (newline)
; -> #(#\a #\b)"xy"
(display (list-copy '(1 2 3))) (display (make-list 3 'x)) (newline)
; -> (1 2 3)(x x x)
(display (string-ci=? "Abc" "aBC")) (write (char-foldcase #\A)) (newline)
; -> #t#\a
(write (list (digit-value #\7) (digit-value #\a))) (newline) ; -> (7 #f)
```

## Numbers

| Procedure                               | Gives                          |
|-----------------------------------------|--------------------------------|
| `(exact X)` `(inexact X)`               | X made exact, or inexact       |
| `(exact-integer? X)`                    | whether X is an exact integer  |
| `(square X)`                            | X times X                      |
| `(exact-integer-sqrt N)`                | two values: the root and the rest |
| `(floor-quotient N D)` `(floor-remainder N D)` | division rounding down  |
| `(truncate-quotient N D)` `(truncate-remainder N D)` | rounding toward 0 |
| `(nan? X)`                              | whether X is not a number      |
| `(boolean=? A B)` `(symbol=? A B)`      | equality for booleans, symbols |

```r7rs
(display (exact 2.0)) (display " ") (display (inexact 1/2)) (newline) ; -> 2 0.5
(display (exact-integer? 5)) (display (square 5)) (newline) ; -> #t25
(display (list (floor-quotient -7 2) (floor-remainder -7 2)
               (truncate-quotient -7 2) (truncate-remainder -7 2)))
(newline)                                               ; -> (-4 1 -3 -1)
(display (nan? (/ 0.0 0.0))) (display (boolean=? #t #t))
(display (symbol=? 'a 'a)) (newline)                    ; -> #t#t#t
```

## String ports

| Procedure                  | Does                                        |
|----------------------------|---------------------------------------------|
| `(open-input-string S)`    | a port that reads S                         |
| `(open-output-string)`     | a port that collects what is written        |
| `(get-output-string PORT)` | what has been written to it                 |
| `(read PORT)` `(read-char PORT)` | a datum; a character                  |

```r7rs
(define out (open-output-string))
(write 'sym out) (display " " out) (write "s" out)
(display (get-output-string out)) (newline)             ; -> sym "s"
(define in (open-input-string "h(1 2) 42"))
(display (read-char in)) (display (read in)) (display (read in))
(display (eof-object? (read in))) (newline)             ; -> h(1 2)42#t
```

## Differs

| Here                                        | In the report                 |
|---------------------------------------------|-------------------------------|
| `(F GET SET)` in a record defines no SET    | SET changes the field         |
| `with-exception-handler` is unbound         | a handler for the body        |
| `raise-continuable` is unbound              | a raise the handler returns to |
| `(vector-copy V 1 3)` copies all of V       | elements 1 and 2              |
| so do `string-copy`, `string->list`, `vector->list` and `string->vector` | |
| `(vector-map + #(1 2) #(10 20))` is #(1 2)  | #(11 22)                      |
| `(round 7/2)` is 7/2                        | 4                             |
| `floor/`, `truncate/` are unbound           | the quotient and rest         |
| `read-line`, `read-string`, `peek-char` are unbound | they read a port      |
| `features` is unbound                       | the list of features          |
| bytevectors are not loaded                  | 6.9                           |
| `define-library` and `import` are not read  | 5.6; all is loaded at once    |

## More

| Where                             | What                                |
|-----------------------------------|-------------------------------------|
| `README.md`                       | what is built, and the suite        |
| the x-r5rs card                   | the R5RS forms this is built on     |
| `tests/contract/known-failures.txt` | each spec that fails, and why     |
| `make card`                       | runs every program on this page     |
