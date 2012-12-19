(define (loop-pwr ms)
  (pwr-on)
  (loop-ms ms)
  (pwr-off)
  (loop-ms ms)
  (loop-pwr ms))

