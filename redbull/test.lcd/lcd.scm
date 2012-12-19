; -------------------------------------------------------------------
;
;  ARMPit Scheme 050 library for:
;
;  Olimex STM32-LCD LCD interface (writing and drawing)
;
;  LCD hardware:
;  -------------
;  ILITEK ILI9320
;  240W x 320H pixels
;  16-bit color RGB (5-6-5)
;  FSMC parallel interface (16-bit cmd/data to address #x6C000000)
;
;  installation from SD card:
;  --------------------------
;  (sd-init) ; wait for bytevector, redo as needed (i.e. if #f)
;  (load "lcdstm32.scm" SDFT)
;  (libs)    ; check for (lcd output) in list
;
;  usage:
;  ------
;  (begin
;    (import (lcd output))
;    (lcd-config)
;    (lcd-init))    ; takes 4-5 seconds
;
;  check:
;  ------
;  (fill 50 50 100 100 #xff00) ; draws colored square
;  (display "HELLO!" lcop)     ; displays greeting on LCD
;
;  boot file example (use separate lines rather than begin):
;  --------------------------------------------------------
;
;  (let ((p (open-output-file "boot")))
;    (if (zero? p) (throw 'FILE "boot"))
;    (write '(import (lcd output)) p)
;    (write '(lcd-config) p)
;    (write '(lcd-init) p)
;    (write '(fill 50 50 100 100 #xff00) p)
;    (write '(display "HELLO!" lcop) p)
;    (close-output-port p)
;    (files))
;
;
; -------------------------------------------------------------------

(library 
 (lcd output)
 (export pixel fill cls LCD0 lcd-config lcd-init lcop)
 (import (system 0) (linker))

 ;; [internal only]
 (define putc
   (unpack-to-lib
    #vu8(223 0 0 0
	 213 248 0 112 215 248 4 112 199 248 36 96 199 248 40 128 79 234
	 131 2 66 240 1 6 199 248 44 96 46 240 1 8 199 248 48 128 3 240
	 255 12 215 248 32 48 156 240 13 15 0 191 12 191 79 234 3 2 215
	 248 8 32 156 240 8 15 0 191 8 191 162 241 4 2 215 248 4 192 178 235
	 3 15 0 191 92 191 79 240 1 2 12 241 4 12 178 241 1 15 0 191 68 191
	 163 241 4 2 172 241 4 12 215 248 28 48 188 241 1 15 0 191 68 191
	 79 240 1 2 163 241 4 12 199 248 4 192 199 248 8 32 215 248
	 16 32 156 234 2 15 0 191 24 191 0 240 6 184 79 240 1 3 79 240
	 8 12 0 240 52 248 213 248 0 112 215 248 4 112 215 248 44 48 79 234
	 147 3 79 240 5 12 0 240 40 248 213 248 0 112 215 248 4 112 215 248
	 48 128 72 240 1 14 215 248 44 48 79 234 147 3 215 248 40 128 215 248
	 36 96 79 240 1 12 199 248 36 192 199 248 40 192 199 248
	 44 192 199 248 48 192 3 240 255 12 188 241 32 15 0 191
	 94 191 215 248 8 32 2 241 4 2 199 248 8 32 247 70 0 191
	 213 248 4 112 12 241 1 12 87 248 44 192 12 241 4 12 231 70 0 191
	 0 0 0 0 0 0 0 0 0 0)))

 ;; [internal only]
 (define lcdptc
   (unpack-to-lib
    #vu8(223 0 0 0
	 46 240 1 8 213 248 4 112 215 248 32 112 3 240 255 12 188 241
	 32 15 0 191 76 191 79 240 1 12 172 241 31 12 188 241
	 96 15 0 191 88 191 79 240 1 12 87 248 44 96 79 240
	 32 3 213 248 0 112 215 248 4 112 215 248 8 192 44 240
	 3 12 12 235 92 12 12 241 1 12 0 240 104 248 79 240 80 3 0 240
	 100 248 79 240 81 3 12 241 4 12 0 240 94 248 79 240
	 33 3 213 248 0 112 215 248 4 112 215 248 4 32 34 240
	 3 12 12 235 92 12 12 235 146 12 12 241 1 12 0 240 76 248
	 79 240 82 3 0 240 72 248 79 240 83 3 12 241 5 12 0 240 66 248
	 79 240 34 3 213 248 0 112 215 248 4 112 215 248 24 192 79 234
	 156 12 76 244 232 28 0 240 52 248 150 240 1 15 0 191 8 191
	 0 240 24 184 79 240 34 3 213 248 0 112 215 248 4 112 182 241
	 0 15 0 191 84 191 215 248 24 192 215 248 20 192 79 234
	 172 12 0 240 28 248 79 234 70 6 134 240 3 6 255 247 226 191
	 79 240 80 3 79 240 0 12 0 240 16 248 79 240 82 3 0 240 12 248
	 79 240 81 3 79 240 239 12 0 240 6 248 79 240 83 3 12 241
	 80 12 72 240 1 14 213 248 4 112 215 248 28 32 2 241 4 2
	 151 70 0 191 0 0 0 0 0 0 0 0 0 0)))

 ;; font
 ;; [internal only]
 (define font
   (unpack-to-lib
    #vu8(79 96 0 0 1 0 0 0 1 2 8 33 1 0 148 82 1 245 213 87 17 95 28 125
	    1 191 136 126 129 103 19 69 1 0 16 17 1 130 16 34 1 34 132 32 129
	    234 190 171 1 66 62 33 33 66 0 0 1 0 62 0 1 198 0 0 1 136 136 8 1
	    183 227 118 129 79 8 101 129 143 76 116 1 31 92 240 129 16 126 140
	    1 23 60 244 1 23 61 116 1 68 68 248 1 23 93 116 1 23 94 116 1 198
	    0 99 33 66 0 99 1 65 16 17 1 240 193 7 1 68 4 65 17 64 76 116 1
	    247 111 116 129 24 127 116 1 31 125 244 1 23 97 116 1 31 99 244 129
	    15 61 252 1 8 61 252 1 23 39 116 129 24 127 140 129 79 8 249 1 38
	    133 56 129 164 152 74 129 15 33 132 129 24 235 142 129 56 107 142
	    1 23 99 116 1 8 125 244 129 38 107 116 129 40 185 228 1 23 28 116
	    1 66 8 249 1 23 99 140 1 162 98 140 129 184 107 140 129 168 136 138
	    1 66 136 138 129 143 136 248 129 135 16 122 129 32 8 130 129 23 66
	    120 1 0 162 34 129 15 0 0 1 0 4 65 129 147 78 48 1 151 28 66 1 131
	    12 0 129 147 78 8 1 131 92 50 1 132 28 58 153 112 210 1 129 148 28
	    66 1 66 8 32 17 37 4 16 129 164 152 66 1 65 8 33 129 90 61 0 129
	    148 28 0 1 147 12 0 33 228 146 3 133 112 210 1 1 164 24 0 1 55 216
	    1 1 65 200 35 129 38 37 0 1 162 34 0 129 87 43 0 1 69 20 0 153 112
	    82 2 129 71 196 3 1 134 32 98 17 66 8 33 1 35 130 48 1 32 42 2 1 0 0 0
	    0 0 0 0 0 0 0 0 0 0 0 0 0)))

 ;; [internal only]
 (define scrlup
   (unpack-to-lib
    #vu8(223 0 0 0
	     46 240 1 8 213 248 0 112 215 248 4 112 215 248 4 192 156 240
	     181 15 0 191 8 191 79 240 1 12 199 248 4 192 12 241
	     4 12 199 248 16 192 79 240 106 3 44 240 3 2 79 234
	     2 12 12 235 92 12 12 235 146 12 0 240 40 248 79 240
	     32 3 79 240 0 12 0 240 34 248 79 240 33 3 213 248
	     0 112 215 248 4 112 215 248 4 32 34 240 3 12 12 235
	     92 12 12 235 146 12 12 241 1 12 0 240 16 248 79 240
	     34 3 213 248 0 112 215 248 4 112 215 248 24 192 79 234
	     156 12 76 244 127 12 76 240 96 108 72 240 1 14 213 248
	     4 112 215 248 28 32 2 241 4 2 151 70 0 191 0 0 0 0 0 0)))

 ;; [internal only]
 (define lcdcmd
   (unpack-to-lib
    (let ((temp
	   #vu8(223 0 0 0
		    223 248 100 112 223 248 100 32 199 248 20 32 79 240
		    6 2 79 234 2 114 162 248 0 48 79 240 72 3 179 241
		    1 3 0 191 24 191 255 247 250 191 223 248 64 32 199 248
		    16 32 79 240 6 2 79 234 2 114 162 248 0 192 79 240
		    72 3 179 241 1 3 0 191 24 191 255 247 250 191 95 234
		    28 67 0 191 28 191 172 245 128 60 255 247 238 191 223 248
		    12 32 199 248 20 32 247 70 0 191 0 0 0 0 0 0 0 0 0 0 0 0)))
      (packed-data-set! temp -2 (address-of gioe 0))
      (packed-data-set! temp -1 (bitwise-arithmetic-shift #vu8(1 0 0 0) 3))
      temp)))

 ;; LCD port model
 (define LCD0
   (unpack-to-lib
    (pack 
     (vector
      #x06C00000
      (vector 1)
      (let ((_OPR (vector-ref UAR0 2)))
	(vector
	 2
	 (vector-ref _OPR 1)
	 (vector-ref _OPR 2)
	 (vector-ref _OPR 3)
	 putc lcdptc lcdcmd font scrlup))))))


 ;; --------------------------------------------
 ;; scheme interfaces
 ;; --------------------------------------------

 ;; (wlcd cmd dat)
 (define wlcd
   (unpack-to-lib
    (let ((temp
	   #vu8(223 2 0 0
		    223 248 32 112 215 248 12 128 216 248 28 128 79 234
		    164 3 79 234 165 12 79 240 15 4 79 234 1 14 8 241
		    4 2 151 70 0 191 0 0 0 0 0 0)))
      (packed-data-set! temp -1 (address-of LCD0 0))
      temp)))

 ;; (pixel x y c)
 (define pixel
   (unpack-to-lib
    (let ((temp
	   #vu8(223 3 0 0
		    223 248 84 112 215 248 12 128 216 248 28 128 79 240
		    32 3 79 234 164 12 12 240 255 12 0 240 26 248 79 240
		    33 3 79 234 165 12 79 240 255 2 66 244 128 114 12 234
		    2 12 0 240 14 248 79 240 34 3 79 234 166 12 79 240
		    255 2 66 244 127 66 12 234 2 12 79 240 15 4 79 234
		    1 14 8 241 4 2 151 70 0 191 0 0 0 0 0 0 0)))
      (packed-data-set! temp -1 (address-of LCD0 0))
      temp)))

 ;; (fill xs ys xe ye col)
 (define fill
   (unpack-to-lib
    (let ((temp
	   #vu8(223 2 0 0
		    223 248 44 113 215 248 12 128 216 248 28 128 79 240 32 3 79 234
		    164 12 0 240 136 248 79 240 33 3 79 234 165 12 0 240 120 248
		    79 240 80 3 79 234 164 12 0 240 124 248 79 240 82 3 79 234
		    165 12 0 240 108 248 79 234 164 2 150 232 80 0 79 234
		    164 12 172 235 2 2 2 241 1 2 79 234 165 3 150 232 96 0 79 234
		    165 12 172 235 3 3 3 241 1 3 2 251 3 242 79 240 81 3 79 234
		    164 12 79 240 1 4 68 234 130 4 0 240 86 248 79 240 83 3 79 234
		    165 12 0 240 70 248 214 248 0 96 79 234 134 50 79 234
		    146 54 180 245 0 63 0 191 72 191 0 240 16 184 79 240 34 3 79 234
		    166 12 79 244 0 66 162 241 1 2 76 234 2 76 0 240 52 248
		    164 245 0 52 255 247 234 191 79 234 164 2 146 240 0 15 0 191
		    8 191 0 240 10 184 162 241 1 2 79 234 166 12 76 234 2 76 79 240
		    34 3 0 240 30 248 79 240 80 3 79 240 0 12 0 240 28 248 79 240
		    82 3 0 240 14 248 79 240 81 3 79 240 239 12 0 240 18 248 79 240
		    83 3 12 241 80 12 79 240 15 4 79 234 1 14 79 240 255 2 66 244
		    128 114 12 234 2 12 8 241 4 2 151 70 0 191 12 240 255 12 255 247
		    248 191 0 0 0 0 0 0 0 0 0 0 0 0 0 0)))
      (packed-data-set! temp -1 (address-of LCD0 0))
      temp)))

 ;; define the clear-screen function
 (define (cls)
   (let* ((stat (cdar (eval 'lcop (interaction-environment))))
	  (bkgn (vector-ref stat 5)))
     (fill 0   0 239 319 bkgn)
     (vector-set! stat 0 (vector-ref stat 5))
     (vector-set! stat 1 0)
     (vector-set! stat 3 (vector-ref stat 6))
     (wlcd #x6a 0)))

 ;; lcop -- the lcd output port
 ;; initialize it using (lcop)
 (define (lcop)
   (eval
    '(define lcop
       (unpack-above-heap
	(pack
	 (cons
	  (cons (vector-ref LCD0 0)
		(vector 0 0 0 45 #xffff 0 45 40 0 0 0 0 0))
	  (vector-ref LCD0 2)))))
    (interaction-environment)))


 ;; LCD is on FSMC Bank1, CS4   ;2
 ;; power-up the needed GPIO pads
 (define (lcd-config)
   (config-power #x18 2 1) ; power-up pad A in rcc_apb2enr (#x18)
   (config-power #x18 5 1) ; power-up pad D in rcc_apb2enr (#x18)
   (config-power #x18 6 1) ; power-up pad E in rcc_apb2enr (#x18)
   (config-power #x18 7 1) ; power-up pad F in rcc_apb2enr (#x18)
   (config-power #x18 8 1) ; power-up pad G in rcc_apb2enr (#x18)
   (config-power #x14 8 1) ; power-up FSMC in rcc_ahbenr
   (config-pin gioa 1 #b01 #b01) ; PA1 = TFT-light   = gpio out, open-drain, 10 MHz
   (pin-set gioa 1) ; back-light off
   ;(config-pin gioe  2 #b01 #b01) ; PE2  = TFT-RST     = gpio out, open-drain, 10 MHz
   (config-pin giof  0 #b00 #b11) ; PF0  = TFT Reg Sel = gpio out, push-pull,  50 MHz
   (pin-clear giof 0) ; Reg Sel off
   (for-each
    (lambda (pin) (config-pin giod pin #b10 #b11))
    '(0 1 8 9 10 14 15 4 5 )) ; D2,3,13-15,0,1, ~OE, ~WE = AF, push-pull, 50 MHz
   (config-pin giog 12 #b10 #b11) ; ~E4 = AF, push-pull, 50 MHz
   (for-each
    (lambda (pin) (config-pin gioe pin #b10 #b11))
    '(7 8 9 10 11 12 13 14 15)) ; D4-12 = AF, push-pull, 50 MHz
   (write #x085010 fsmc  #x18) ; BCR4  <- SRAM, 16-bit, extended mode
   (write #x000811 fsmc  #x1c) ; BTR4  <- read:  14ns addr set, dat hold, 112ns dat set
   (write #x000113 fsmc #x11c) ; BWTR4 <- write: 14ns addr set, dat hold,  42ns dat set
   (register-copy-bit fsmc #x18 0 1) ; BCR4 <- enable Bank1 CS4 (SRAM)
   (lcop))

 ;; simple wait function
 (define (lcd-wait n)
   (if (positive? n) (lcd-wait (- n 1))))

 ;; writing a 16-bit half-word to the LCD
 (define u16w
   (unpack-to-lib
    #vu8(223 1 0 0
	     79 234 164 3 79 240 6 2 79 234 2 114 162 248
	     0 48 79 240 31 4 143 70 0 191 0)))

 ;; reading a lcd register
 (define (lcd-rd reg)
   (pin-clear giof 0)
   (u16w reg)
   (pin-set giof 0)
   (let ((val (bitwise-and #xffff (read #x6C00000 0))))
     (pin-clear giof 0)
     val))
 
 ;; initialize and clear the LCD
 (define (lcd-init)
   ;(pin-clear gioe 2) ;reset
   ;(lcd-wait 2000)
   ;(pin-set gioe 2) ;reset
   (lcd-wait 8000)
   (let loop ((n 1000))
     (if (zero? n) (throw "lcd-init" "time-out"))
     (if (= #x9320 (lcd-rd 0)) #t
	 (begin (lcd-wait 1000)
		(loop (- n 1)))))
   (for-each wlcd '(#xe5 #x00) '(#x8000 #x01))
   (lcd-wait 1000)
   (for-each wlcd '(#xa4 #x07) '(#x01 #x00))
   (lcd-wait 1000)
   (for-each wlcd '(1 2 3 4 8 9) '(#x100 #x700 #x1030 #x00 #x0202 #x00))
   (lcd-wait 1000)
   (for-each wlcd '(#x07 #x17 #x10 #x11 #x12 #x13) '(#x0101 #x01 #x00 #x07 #x00 #x00))
   (lcd-wait 1000)
   (for-each wlcd '(#x10 #x11) '(#x16B0 #x37))
   (lcd-wait 1000)
   (wlcd #x12 #x013E)
   (lcd-wait 1000)
   (for-each wlcd '(#x13 #x29) '(#x1a00 #x0f))
   (lcd-wait 1000)
   (for-each wlcd
	     '(#x20 #x21 #x50 #x51 #x52 #x53   #x60   #x61 #x6A)
	     '(#x00 #x00 #x00 #xef #x00 #x013f #x2700 #x03 #x00))
   (lcd-wait 1000)
   (lcd-wait 1000)
   (for-each wlcd '(#x90 #x92 #x93) '(#x10 #x00 #x00))
   (lcd-wait 1000)
   (wlcd #x07 #x0173)
   (cls)
   (pin-clear gioa 1)) ; back-light on

 ) ; end of library

