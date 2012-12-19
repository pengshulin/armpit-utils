; redbull board based on STM32F103ZE
(define _ticks-ms 20)

(define (loop-ms ms) 
  (if (not (zero? ms))
      (begin (loop-tick _ticks-ms)
             (loop-ms (- ms 1)))))

; enable all peripherals' clock
(begin
  ; rcc_apbenr(#x14)
  ;(config-power #x14 0 1)  ; DMA1(bit0)
  ;(config-power #x14 1 1)  ; DMA2(bit1)
  ;(config-power #x14 2 1)  ; SRAM(bit2)
  ;(config-power #x14 4 1)  ; FLITF(bit4)
  ;(config-power #x14 6 1)  ; CRC(bit6)
  (config-power #x14 8 1)  ; FSMC(bit8)
  ;(config-power #x14 10 1)  ; SDIO(bit10)
  ; rcc_apb2enr(#x18)
  (config-power #x18 0 1)  ; AFIO(bit0)
  (config-power #x18 2 1)  ; IOPA(bit2)
  (config-power #x18 3 1)  ; IOPB(bit3)
  (config-power #x18 4 1)  ; IOPC(bit4)
  (config-power #x18 5 1)  ; IOPD(bit5)
  (config-power #x18 6 1)  ; IOPE(bit6)
  (config-power #x18 7 1)  ; IOPF(bit7)
  (config-power #x18 8 1)  ; IOPG(bit8)
  (config-power #x18 9 1)  ; ADC1(bit9)
  ;(config-power #x18 10 1)  ; ADC2(bit10)
  (config-power #x18 11 1)  ; TIM1(bit11)
  (config-power #x18 12 1)  ; SPI1(bit12)
  ;(config-power #x18 13 1)  ; TIM8(bit13)
  (config-power #x18 14 1)  ; USART1IOPG(bit14)
  ;(config-power #x18 15 1)  ; ADC3(bit15)
  ;(config-power #x18 19 1)  ; TIM9(bit19)
  ;(config-power #x18 20 1)  ; TIM10(bit20)
  ;(config-power #x18 21 1)  ; TIM11(bit21)
  )


; LED1~5: GPIOF[6:10] 
(define (led-set? id)
  (not (pin-set? giof (+ id 6))))

(define (led-set id)
  (pin-clear giof (+ id 6)))

(define (led-clear id)
  (pin-set giof (+ id 6)))

(define (led-toggle id)
  (if (led-set? id)
      (led-clear id)
      (led-set id)))

(begin  ; init
  (for-each
    (lambda (pin)
      (config-pin giof pin #b01 #b10) ; output,open-drain,2MHz
      (pin-set giof pin))  ; default: led off
    '(6 7 8 9 10)))

; BEEP: GIOB[2]
(begin
  (config-pin giob 2 #b00 #b10) ; output,push-pull,2MHz
  (pin-clear giob 2))

(define (beep-ms ms)
  (pin-set giob 2)
  (loop-ms ms)
  (pin-clear giob 2))

(define (beep)  (beep-ms 50))

; KEYs
;   WAKEUP: PA0
;   TAMPER: PC13
;   USER1: PA8
;   USER2: PD3
(begin  ; init
  (config-pin gioa 0 #b01 #b00) ; input,floating
  (config-pin gioc 13 #b01 #b00) ; input,floating
  (config-pin gioa 8 #b01 #b00) ; input,floating
  (config-pin giod 3 #b01 #b00) ; input,floating
  )

(define (key-wakeup-pressed?)  (not (pin-set? gioa 0)))
(define (key-tamper-pressed?)  (not (pin-set? gioc 13)))
(define (key-user1-pressed?)  (not (pin-set? gioa 8)))
(define (key-user2-pressed?)  (not (pin-set? giod 3)))



; FSMC:
; D0 - GPD14
; D1 -    15
; D2 - GPD0
; D3 -   D1
; D4 - GPE7
; D5 -    8
; D6 -    9
; D7 -    10
; D8 -    11
; D9 -    12
; D10 -   13
; D11 -   14
; D12 -   15
; D13 - GPD8
; D14 -    9
; D15 -    10

