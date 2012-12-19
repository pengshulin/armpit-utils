; pyeasycontrol control module based on STM32F103RBVT
(define _ticks-ms 20)

(define (loop-ms ms) 
  (if (not (zero? ms))
      (begin (loop-tick _ticks-ms)
             (loop-ms (- ms 1)))))

; enable all periphals' clock
(begin
  (config-power #x18 3 1)  ; rcc_apb2enr(#x18) -> IOPB(bit3)
  (config-power #x18 4 1)  ; rcc_apb2enr(#x18) -> IOPC(bit4)
  )
 
; LED0~1: GPIOB[0:1] 
(define (led-set id)
  (pin-set giob id))

(define (led-clear id)
  (pin-clear giob id))

(begin  ; led-init
  (config-pin giob 0 #b00 #b10) ; output,push-pull,2MHz
  (led-set 0)
  (config-pin giob 1 #b00 #b10) ; output,push-pull,2MHz
  (led-clear 1))

; PWR-EN: GPIOB[6] 
(define (pwr-on)
  (config-pin giob 6 #b01 #b01) ; output,open-drain,2MHz
  (pin-clear giob 6))

(define (pwr-off)
  (config-pin giob 6 #b01 #b00)) ; input,floating

(pwr-on)


; XPORT[0-15]: GPIOC[0:15] 
(define (xport-dir-in id)
  (config-pin gioc id #b01 #b00)) ; input,floating

(define (xport-dir-out id)
  (config-pin gioc id #b00 #b01)) ; output,push-pull,10MHz

(define (xport-dir-out-all)
  (for-each xport-dir-out '(0 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15)))

(define (xport-dir-in-all)
  (for-each xport-dir-in '(0 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15)))

(define (xport-set id)
  (pin-set gioc id))

(define (xport-set? id)
  (pin-set? gioc id))

(define (xport-clear id)
  (pin-clear gioc id))

(xport-dir-in-all)  ; init all xport pin as input

