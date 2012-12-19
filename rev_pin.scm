; rev gpio pin looply

(define (rev-pin rev-port rev-pin ms-on ms-off led-id)
  ; configure pin as push-pull
  (config-pin rev-port rev-pin  #b00 #b10)
  ; configure rev function
  (define (rev-pin-loop rev-port rev-pin ms-on ms-off led-id)
    (pin-set rev-port rev-pin)
    (led-set led-id)
    (loop-ms ms-on)
    (pin-clear rev-port rev-pin)
    (led-clear led-id)
    (loop-ms ms-off)
    (rev-pin-loop rev-port rev-pin ms-on ms-off led-id)
    )
  ; looply reverse pin
  (rev-pin-loop rev-port rev-pin ms-on ms-off led-id)
  )
  

