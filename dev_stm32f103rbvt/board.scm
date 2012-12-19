; STM32F103RBVT minimal dev board
(define _ticks-ms 20)

(define (loop-ms ms) 
  (if (not (zero? ms))
      (begin (loop-tick _ticks-ms)
             (loop-ms (- ms 1)))))

; enable all peripherals' clock
(begin
  (config-power #x18 0 1)  ; rcc_apb2enr(#x18) -> AFIO(bit0)
  (config-power #x18 2 1)  ; rcc_apb2enr(#x18) -> IOPA(bit2)
  (config-power #x18 3 1)  ; rcc_apb2enr(#x18) -> IOPB(bit3)
  (config-power #x18 4 1)  ; rcc_apb2enr(#x18) -> IOPC(bit4)
  (config-power #x18 5 1)  ; rcc_apb2enr(#x18) -> IOPD(bit5)
  (config-power #x18 6 1)  ; rcc_apb2enr(#x18) -> IOPE(bit6)
  (config-power #x18 7 1)  ; rcc_apb2enr(#x18) -> IOPF(bit7)
  (config-power #x18 8 1)  ; rcc_apb2enr(#x18) -> IOPG(bit8)
  )

; LED0~1: GPIOC[0:1] 
(define port-led gioc)

(define (led-set id)
  (pin-clear port-led id))

(define (led-clear id)
  (pin-set port-led id))

(define (led-toggle id)
  (if (pin-set? port-led id)
      (pin-clear port-led id)
      (pin-set port-led id)))

(begin  ; led init
  (for-each
    (lambda (pin)
      (config-pin port-led pin #b01 #b01) ; output,open-drain,10MHz
      (pin-set port-led pin))
    '(0 1)))


