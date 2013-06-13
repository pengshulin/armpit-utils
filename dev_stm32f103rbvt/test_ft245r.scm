; test ft245r
; write 0,1,2,3,...,255,0,1,2,... looply, as fast as possible
(define port-wr   gioa)
(define pin-wr    1)
(define port-txe  gioa)
(define pin-txe   2)
(define port-dat  gioc)

(config-pin port-wr pin-wr  #b00 #b10) ; output, push-pull
(config-pin port-txe pin-txe  #b01 #b00) ; input, floating
(config-pin port-dat 0  #b00 #b10) ; output, push-pull
(config-pin port-dat 1  #b00 #b10) ; output, push-pull
(config-pin port-dat 2  #b00 #b10) ; output, push-pull
(config-pin port-dat 3  #b00 #b10) ; output, push-pull
(config-pin port-dat 4  #b00 #b10) ; output, push-pull
(config-pin port-dat 5  #b00 #b10) ; output, push-pull
(config-pin port-dat 6  #b00 #b10) ; output, push-pull
(config-pin port-dat 7  #b00 #b10) ; output, push-pull

(pin-clear port-wr pin-wr)

(define data 0)

(define (prepare-dat-pin pin)
  (if (bitwise-bit-set? data pin)
    (pin-set port-dat pin)
    (pin-clear port-dat pin)))

;(define (prepare-dat)
;  (for-each
;    prepare-dat-pin
;    '(0 1 2 3 4 5 6 7)))
(define (prepare-dat)
  (write data 67113216 12))

(define (wait-for-txe)
  (if (pin-set? port-txe pin-txe)
     (wait-for-txe)))

(define (test)
  (pin-set port-wr pin-wr)
  (prepare-dat)
  (set! data (+ data 1))
  (wait-for-txe)
  (pin-clear port-wr pin-wr)
  (test))

(test)

