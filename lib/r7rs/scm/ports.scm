; --- Ports (R7RS 6.13) ---
;
; This file extends the R5RS port layer (x-r5rs, r5rs/scm/ports.scm), which
; provides the representation, the predicates, read-char, read and the file
; procedures. What R7RS adds is string ports, built on that layer's %strsrc
; source: a string port is a string and a cursor, nothing else.

; --- Port extensions (R7RS §6.13) ---

(define (port? x) (or (input-port? x) (output-port? x)))
(define (close-port p)
  (cond ((input-port? p) (close-input-port p))
        ((output-port? p) (close-output-port p))))

; --- String input ports (R7RS §6.13.3) ---
;
; %strsrc carries the string and the cursor; %make-port wraps it as an
; ordinary input port.  read-char, peek-char and read all reach it through
; %src-getc without knowing it is not a file.
(define (open-input-string str) (%make-port 'input (%strsrc str)))

; close on a string port has nothing to release -- there is no descriptor --
; but it must still answer, because R7RS lets a program close any port it
; opened.  Closing an fd port keeps the R5RS behaviour.
(define (close-input-port p)
  (if (%strsrc? (%port-fd p)) '() (File close (%port-fd p))))

; --- String output ports (R7RS §6.13.3) -----------------------------------
;
; The R5RS layer is emphatic that nothing may shadow the renderers, and this
; file does not: a port argument is a SCOPED REDIRECT.  %out-fd already
; selects where the platform's printer emits, and %sink-put! already accepts
; a %strsink there, so (display x p) is display -- the real one, reaching
; every renderer it always reached -- with the sink pointed at p's box for
; the duration of the call.
;
; What is shadowed is only the ARITY.  R7RS gives display, write, write-char
; and newline an optional port argument; R5RS gives them none.  Each wrapper
; below delegates to the captured original and adds nothing but the redirect.
(define (open-output-string) (%make-port 'output (%strsink)))
(define (get-output-string p) (%strsink-str (%port-fd p)))

; Restores the destination but not the sink, for the reason with-output-to-file
; gives: a transcript may be installed underneath and must outlive this.
(define (%with-port-out p thunk)
  (let ((saved (car %out-fd)))
    (do
      (%sink-install!)
      (set-car! %out-fd (%port-fd p))
      (let ((r (thunk)))
        (do (set-car! %out-fd saved) r)))))

; The platform's display is variadic -- (display a "/" b) is how rational.x
; renders 10/3 -- so R7RS's optional port argument cannot be told from a
; variadic operand by arity alone. Dispatch on the value: one extra argument
; that is a port is R7RS's port argument; anything else is passed straight
; through. Getting this wrong hands a garbage descriptor to File write.
(define %base-display display)
(define %base-write write)
(define %base-write-char write-char)
(define %base-newline newline)

(define (%port-arg? rest)
  (and (pair? rest) (null? (cdr rest)) (port? (car rest))))

(define (display x . rest)
  (cond ((null? rest) (%base-display x))
        ((%port-arg? rest)
         (%with-port-out (car rest) (lambda () (%base-display x))))
        (else (apply %base-display (cons x rest)))))

(define (write x . rest)
  (cond ((null? rest) (%base-write x))
        ((%port-arg? rest)
         (%with-port-out (car rest) (lambda () (%base-write x))))
        (else (apply %base-write (cons x rest)))))

(define (write-char c . rest)
  (cond ((null? rest) (%base-write-char c))
        ((%port-arg? rest)
         (%with-port-out (car rest) (lambda () (%base-write-char c))))
        (else (apply %base-write-char (cons c rest)))))

(define (newline . rest)
  (cond ((null? rest) (%base-newline))
        ((%port-arg? rest)
         (%with-port-out (car rest) (lambda () (%base-newline))))
        (else (apply %base-newline rest))))

; Symmetric with close-input-port: a string port holds no descriptor.
(define (close-output-port p)
  (if (%strsink? (%port-fd p)) '() (File close (%port-fd p))))
