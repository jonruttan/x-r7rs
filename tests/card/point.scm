(define-record-type point (make-point x y) point? (x point-x) (y point-y))
(define (dist p) (exact (sqrt (+ (square (point-x p)) (square (point-y p))))))
(display (dist (make-point 3 4)))
(newline)
