(define ash bitwise-arithmetic-shift)

(define (halt) (halt))

(define (message msg)
  (display msg)
  (newline))

(define (loop-tick n)
  (if (not (zero? n)) (loop-tick (- n 1))))


