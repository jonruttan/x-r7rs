# @weight 4

## error

### error raises exception

```scheme
(guard (e (#t #t)) (error "boom"))
```
---
    #t

### error creates error object

```scheme
(guard (e (#t (error-object? e))) (error "boom"))
```
---
    #t

### error-object-message

```scheme
(guard (e (#t (error-object-message e))) (error "boom"))
```
---
    "boom"

### error-object-irritants empty

```scheme
(guard (e (#t (null? (error-object-irritants e)))) (error "oops"))
```
---
    #t

### error with irritants

```scheme
(guard (e (#t (error-object-irritants e))) (error "fail" 1 2 3))
```
---
    (1 2 3)

### error-object-message with irritants

```scheme
(guard (e (#t (error-object-message e))) (error "fail" 42))
```
---
    "fail"

## guard

### guard catches error

```scheme
(guard (e (#t (list (quote caught) (error-object-message e)))) (error "fail"))
```
---
    (caught "fail")

### guard returns body when no error

```scheme
(guard (e (#t (quote caught))) (+ 1 2))
```
---
    3

### guard with multiple body forms

```scheme
(guard (e (#t (quote caught))) 1 2 (+ 3 4))
```
---
    7

### guard handler uses error message

```scheme
(guard (e (#t (+ (error-object-message e) 1))) (error 41))
```
---
    42

## guard with computation

### guard in let

```scheme
(let ((x 10)) (guard (e (#t (+ x 1))) (error "fail")))
```
---
    11

### guard in define

```scheme
(define (safe-op) (guard (e (#t 0)) (error "fail"))) (safe-op)
```
---
    0

### guard passes through normal value

```scheme
(guard (e (#t (quote bad))) (list 1 2 3))
```
---
    (1 2 3)

### guard passes through arithmetic

```scheme
(guard (e (#t (quote bad))) (* 6 7))
```
---
    42

## guard with cond clauses

### guard with error-object clause

```scheme
(guard (e ((error-object? e) (string-append "Error: " (error-object-message e))) (#t "other"))
  (error "boom"))
```
---
    "Error: boom"

### guard with else clause

```scheme
(guard (e ((number? e) "number") (else "else"))
  (error "boom"))
```
---
    else

### guard error-object? always matches

```scheme
(guard (e ((error-object? e) (* (error-object-message e) 2)) (else "other"))
  (error 21))
```
---
    42

## raise

### raise hands guard the object as it is

```scheme
(guard (e (#t e)) (raise 21))
```
---
    21

### a guard clause tests the raised object

```scheme
(guard (e ((number? e) (* e 2))) (raise 21))
```
---
    42

### a raised symbol

```scheme
(guard (e ((symbol? e) (list (quote sym) e))) (raise (quote oops)))
```
---
    (sym oops)

### a raised string is not an error object

```scheme
(guard (e ((error-object? e) (quote err)) ((string? e) (string-append "s:" e))) (raise "oops"))
```
---
    "s:oops"

### a raised list

```scheme
(guard (e ((pair? e) (car e))) (raise (list 1 2)))
```
---
    1

### the clause after one that fails

```scheme
(guard (e ((string? e) (quote str)) ((number? e) (quote num))) (raise 7))
```
---
    num
