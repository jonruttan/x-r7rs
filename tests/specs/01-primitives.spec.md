# @weight 4

## quotation

### quote symbol

```scheme
(quote a)
```
---
    a

### quote list

```scheme
(quote (+ 1 2))
```
---
    (+ 1 2)

### quote number is identity

```scheme
(quote 42)
```
---
    42

### quote string is identity

```scheme
(quote "hello")
```
---
    "hello"

## lambda

### lambda application

```scheme
((lambda (x) (+ x x)) 4)
```
---
    8

### lambda with rest args

```scheme
((lambda x x) 3 4 5 6)
```
---
    (3 4 5 6)

### lambda with required and rest

```scheme
((lambda (x y . z) z) 3 4 5 6)
```
---
    (5 6)

### lambda no args

```scheme
((lambda () 42))
```
---
    42

### lambda multiple body forms

```scheme
((lambda (x) (+ x 1) (+ x 2)) 10)
```
---
    12

### nested lambda

```scheme
(((lambda (x) (lambda (y) (+ x y))) 3) 4)
```
---
    7

## if

### if true branch

```scheme
(if (> 3 2) (quote yes) (quote no))
```
---
    yes

### if false branch

```scheme
(if (> 2 3) (quote yes) (quote no))
```
---
    no

### if no else returns nil

```scheme
(null? (if #f 1))
```
---
    #t

### if non-false is true

```scheme
(if 0 (quote yes) (quote no))
```
---
    yes

### if nil is false

```scheme
(if () (quote yes) (quote no))
```
---
    no

## define

### define variable

```scheme
(define x 28) x
```
---
    28

### define function shorthand

```scheme
(define (f x) (+ x 1)) (f 10)
```
---
    11

### define with expression body

```scheme
(define x (* 3 4)) x
```
---
    12

### redefine variable

```scheme
(define x 1) (define x 2) x
```
---
    2

## set!

### set! mutates binding

```scheme
(define x 1) (set! x 2) x
```
---
    2

### set! in nested scope

```scheme
(define x 10) (let ((y 0)) (set! x 20)) x
```
---
    20


## define from a nested frame

### binds the top-level name from inside a procedure's frame

```scheme
(define (%r7rs-dg-set) (if #t (define %r7rs-dg-probe 7) #f)) (%r7rs-dg-set) %r7rs-dg-probe
```
---
    7

### and through a frame interposed above it

```scheme
(define (%r7rs-dg-inner) (if #t (define %r7rs-dg-deep 9) #f)) (define (%r7rs-dg-outer) (%r7rs-dg-inner)) (%r7rs-dg-outer) %r7rs-dg-deep
```
---
    9

### a redefinition at depth updates the top-level cell in place

```scheme
(define %r7rs-dg-twice 1) (define (%r7rs-dg-again) (if #t (define %r7rs-dg-twice 2) #f)) (%r7rs-dg-again) %r7rs-dg-twice
```
---
    2

### from a guarded body inside a procedure's frame

```scheme
(define (%r7rs-dg-guarded) (guard (e (#t 0)) (if #t (define %r7rs-dg-body 11) #f))) (%r7rs-dg-guarded) %r7rs-dg-body
```
---
    11

### from a guard handler

```scheme
(guard (e (#t (define %r7rs-dg-handled 5))) (error "boom")) %r7rs-dg-handled
```
---
    5
