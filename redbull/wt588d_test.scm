; test wt588d module
; spi-data - PC0
; spi-cs   - PC1
; spi-clk  - PC2

(begin ; board-init
  (config-pin gioc 0 #b01 #b00)  ; input,floating
  (config-pin gioc 1 #b01 #b00)  ; input,floating
  (config-pin gioc 2 #b01 #b00)  ; input,floating
  (config-pin gioc 3 #b01 #b00)  ; input,floating
  (config-pin gioc 4 #b00 #b10)  ; output,power
  (pin-set gioc 4)
  )

(define (reset)
  (pin-clear gioc 3)
  (loop-ms 5)  ; must > 5ms
  (pin-set gioc 3)
  (loop-ms 20))  ; must > 20ms

(define (spi-init)
  (config-pin gioc 0 #b01 #b01)  ; output,open-drain,10MHz
  (config-pin gioc 1 #b01 #b01)  ; output,open-drain,10MHz
  (config-pin gioc 2 #b01 #b01)  ; output,open-drain,10MHz
  (config-pin gioc 3 #b01 #b01)  ; output,open-drain,10MHz
  (pin-set gioc 0)
  (pin-set gioc 1)
  (pin-set gioc 2)
  (pin-set gioc 3))


(define spi-bit-delay 5)

(define (spi-send-bit high)
  (pin-clear gioc 2)  ; clk low
  ((if (zero? high) pin-clear pin-set) gioc 0)  ; push bit out
  (loop-tick spi-bit-delay)
  (pin-set gioc 2)  ; clk high
  (loop-tick spi-bit-delay)
  )

(define (spi-send-byte val)
  (display val)
  (newline)
  (pin-clear gioc 1)  ; cs low
  (loop-ms 5)  ; wait 5 ms
  (spi-send-bit (bitwise-and val #x01))
  (spi-send-bit (bitwise-and val #x02))
  (spi-send-bit (bitwise-and val #x04))
  (spi-send-bit (bitwise-and val #x08))
  (spi-send-bit (bitwise-and val #x10))
  (spi-send-bit (bitwise-and val #x20))
  (spi-send-bit (bitwise-and val #x40))
  (spi-send-bit (bitwise-and val #x80))
  (pin-set gioc 0)  ; data high
  (loop-ms 20)  ; wait 20 ms
  (pin-set gioc 1)  ; cs high
  )


(define setting-volume 7)

(define setting-address 0)

(define setting-volume-up-mode #t)

(define (volume setting)
  (cond ((< setting 0)  (set! setting-volume 0))
        ((> setting 7)  (set! setting-volume 7))
        (else  (set! setting-volume setting)))
  (spi-send-byte (bitwise-xor #xE0 setting-volume)))

(define (set-next-volume)
  (set! setting-volume ((if setting-volume-up-mode + -) setting-volume 1))
  (cond ((= setting-volume -1)
         (begin (set! setting-volume 1)
                (set! setting-volume-up-mode #t)))
        ((= setting-volume 8)
         (begin (set! setting-volume 6)
                (set! setting-volume-up-mode #f)))))

(define (address setting)
  (cond ((< setting 0)  (set! setting-address 0))
        ((> setting #xDB)  (set! setting-address #xDB))
        (else  (set! setting-address setting)))        
  (spi-send-byte setting-address))

(define (loop-play)  (spi-send-byte #xF2))

(define (play)  (spi-send-byte setting-address))

(define (stop)  (spi-send-byte #xFE))


; test
(led-set 0)
(loop-ms 500)  ; wait for power stability
(spi-init)
(loop-ms 500)
(reset)
(led-clear 0)

(volume 1)
(address 0)
(stop)
;(loop-play)


; in autorun mode

(define key-wakeup-hook (lambda () (address (+ setting-address 1))))
(define key-tamper-hook (lambda () (address (- setting-address 1))))
(define key-user1-hook (lambda () (stop)))
(define key-user2-hook (lambda () (begin (set-next-volume) 
                                         (volume setting-volume))))


(load "key_test.scm")



