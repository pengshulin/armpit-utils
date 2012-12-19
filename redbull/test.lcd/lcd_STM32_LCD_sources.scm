
; -------------------------------------------------------------------
;
;  ARMPit Scheme 050
;
;  Source code for ARMSchembly interface functions used
;  in LCD interface library for Olimex STM32-LCD.
;
;  Target LCD hardware:
;  --------------------
;
;  ILITEK ILI9320
;  240W x 320H pixels
;  16-bit color RGB (5-6-5)
;  FSMC parallel interface (16-bit cmd/data to address #x60000000)
;
;  Functions:
;  ----------
;
;  lcdcmd
;  wlcd
;  putc
;  lcdptc
;  scrlup
;  pixel
;  fill
;  u16w
;
; -------------------------------------------------------------------
;
; some (at least) sources can be ARMSchembled on-chip, eg, after:
;
; (import (as) (as const))
;
; (as-init)
;
; -------------------------------------------------------------------


; -------------------------------------------------------------------
; lcdcmd:	write command in rvb and data in rvc to LCD
; -------------------------------------------------------------------
; on entry:	rvb <- lcd command
; on entry:	rvc <- lcd data (low 16), repeat count (high 14/16)
; on entry:	lnk <- return address
; modifies:	sv4, rva, rvb, rvc (high 16)
; preserves:	rvc (low 16), sv1-sv3, sv5, cnt, fre
; -------------------------------------------------------------------
(define
  vcod
  (assemble
   'var 0
   '(;; write out command
     (ldr sv4 lcdcmddatgio)        ; sv4 <- port address for cmd/dat
     (ldr rva lcdcmddatpin)
     (str rva sv4 #x14)            ; cmd/dat pin low
     (set! rva #x06)
     (lsl rva rva 28)
     (strh rvb rva)                ; write cmd
     ;; wait 2us (increase this if pixels are missing or mangled)
     (set! rvb 72)
     wait1
     (s sub rvb rvb 1)
     (if (ne b wait1))
     ;; write out data
     (ldr rva lcdcmddatpin)
     (str rva sv4 #x10)            ; cmd/dat pin high
     (set! rva #x06)
     (lsl rva rva 28)
     lcmdlp
     (strh rvc rva)                ; write data
     ;; wait 2 us (increase this if pixels are missing or mangled)
     (set! rvb 72)
     wait2
     (s sub rvb rvb 1)
     (if (ne b wait2))
     ;; check for more data
     (s lsr rvb rvc 16)		   ; more data?
     (if (ne sub rvc rvc #x010000) ;    if so,  rvc <- data count - 1
	 (ne b lcmdlp))		   ;    if so,  jump back to put pixels
     ;; finish up
     (ldr rva lcdcmddatpin)
     (str rva sv4 #x14)            ; cmd/dat pin low
     (set! pc lnk)		   ; return
     ;; storage space
     lcdcmddatgio  (0 . 0) 	   ; lcd cmd/dat line port (eg. gioe)
     lcdcmddatpin  (0 . 0)))) 	   ; lcd cmd/dat pin (eg. 1<<3 for PE.3)

; resulting code
vcod ; ->
#vu8(223 0 0 0
     223 248 100 112 223 248 100 32 199 248 20 32 79 240
     6 2 79 234 2 114 162 248 0 48 79 240 72 3 179 241
     1 3 0 191 24 191 255 247 250 191 223 248 64 32 199 248
     16 32 79 240 6 2 79 234 2 114 162 248 0 192 79 240
     72 3 179 241 1 3 0 191 24 191 255 247 250 191 95 234
     28 67 0 191 28 191 172 245 128 60 255 247 238 191 223 248
     12 32 199 248 20 32 247 70 0 191 0 0 0 0 0 0 0 0 0 0 0 0)


; -------------------------------------------------------------------
; wlcd:	 interface to be called from scheme for lcdcmd
; -------------------------------------------------------------------
; on entry:	sv1 <- command (scheme int)
; on entry:	sv2 <- data+repeat-count (scheme int)
; on exit:	sv1 <- '()
; modifies:	sv1, rva, rvb, rvc (and sv4 via lcdcmd)
; -------------------------------------------------------------------

; (wlcd cmd dat)
(define
  vcod
  (assemble
   'var 2               ; sv1 <- command, sv2 <- data+repeat-count
   '(;; get address of lcdcmd from port model
     (ldr sv4 lcd_pm)   ; sv4 <- port-model
     (vcrfi sv5 sv4 2)  ; sv5 <- output-port vector
     (vcrfi sv5 sv5 6)  ; sv5 <- address of lcdcmd
     ;; perform command
     (int->raw rvb sv1)	; rvb <- raw command
     (int->raw rvc sv2)	; rvc <- raw data (L16), repeat count (H14)
     (set! sv1 $null)	; sv1 <- '() = return value
     (set! lnk cnt)     ; lnk <- return address for jump to lcdcmd
     (add rva sv5 4)	; rva <- start address of lcdcmd primitive
     (set! pc rva)	; jump to lcdcmd
     ;; storage space
     lcd_pm  (0 . 0))))	; hole for port-model

; resulting code
vcod ; ->
#vu8(223 2 0 0
	 223 248 32 112 215 248 12 128 216 248 28 128 79 234
	 164 3 79 234 165 12 79 240 15 4 79 234 1 14 8 241
	 4 2 151 70 0 191 0 0 0 0 0 0)


; -------------------------------------------------------------------
; putc:		port function
; -------------------------------------------------------------------
; on entry:	sv1 <- scheme char or string to write out
; on entry:	sv2 <- ((port . status-&-storage) . port-vector) = full output port
; on entry:	sv3 <- saved lnk from caller of caller
; on entry:	sv4 <- nothing, maybe port address
; on entry:	sv5 <- saved lnk from caller
; on entry:	rvb <- ascii char to be written + offset of char in string (if string)
; preserves:	sv1, sv2, sv3, sv5, rvb
; modifies:	rva, rvc, sv4
; -------------------------------------------------------------------

(define vcod
  (assemble
   'var 0
   '(;; save sv3, sv5, char(rvb) and lnk into port status-storage vector
     (cdar sv4 sv2)
     (vcsti sv4 8 sv3)
     (vcsti sv4 9 sv5)
     (lsl rva rvb 2)
     (orr sv3 rva $i0)
     (vcsti sv4 10 sv3)
     (bic sv5 lnk $i0)
     (vcsti sv4 11 sv5)
     ;; update position relative to left-edge, scroll
     (and rvc rvb #xff)
     (vcrfi rvb sv4 7)
     (eq? rvc 13)
     (if (eq set! rva rvb)
	 (ne vcrfi rva sv4 1))
     (eq? rvc 8)
     (if (eq sub rva rva 4))
     (vcrfi rvc sv4 0)
     (cmp rva rvb)
     (if (pl set! rva $i0)
	 (pl add rvc rvc 4))
     (cmp rva $i0)
     (if (mi sub rva rvb 4)
	 (mi sub rvc rvc 4))
     (vcrfi rvb sv4 6)
     (cmp rvc $i0)
     (if (mi set! rva $i0)
	 (mi sub rvc rvb 4))
     (vcsti sv4 0 rvc)
     (vcsti sv4 1 rva)
     (vcrfi rva sv4 3)
     (eq? rvc rva)
     (if (ne b scrskp))
     ;; scroll display up
     (set! rvb 1)
     (set! rvc 8)
     (bl rvcjmp)
     scrskp
     ;; display character
     (cdar sv4 sv2)
     (vcrfi rvb sv4 10)
     (lsr rvb rvb 2)
     (set! rvc 5)
     (bl rvcjmp)
     ;; finish up (restore saved registers)
     (cdar sv4 sv2)
     (vcrfi sv5 sv4 11)
     (orr lnk sv5 $i0)
     (vcrfi rvb sv4 10)
     (lsr rvb rvb 2)
     (vcrfi sv5 sv4 9)
     (vcrfi sv3 sv4 8)
     (set! rvc $i0)
     (vcsti sv4  8 rvc)
     (vcsti sv4  9 rvc)
     (vcsti sv4 10 rvc)
     (vcsti sv4 11 rvc)
     ;; update character position in LCD status vector (do not worry about edge, scroll)
     (and rvc rvb #xff)
     (cmp rvc #x20)
     (if (pl vcrfi rva sv4 1)
	 (pl add rva rva 4)
	 (pl vcsti sv4 1 rva))
     ;; return
     (set! pc lnk)
     ;; jump to function in rvc (called with bl)
     rvcjmp
     (cdr sv4 sv2)
     (add rvc rvc 1)
     (ldr rvc sv4 lsl rvc 2)
     (add rvc rvc 4)
     (set! pc rvc))))

; resulting code vector (vcod):
vcod ; ->
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
	 0 0 0 0 0 0 0 0 0 0)


; -------------------------------------------------------------------
; lcdptc:	display character
; -------------------------------------------------------------------
; on entry:	sv2 <- full output port
; on entry:	rvb <- ascii char to display
; modifies:	rva, rvb, rvc, sv3-sv5
; -------------------------------------------------------------------

(define vcod
  (assemble
   'var 0
   '((bic sv5 lnk $i0)
     ;; get font
     (cdr sv4 sv2)
     (vcrfi sv4 sv4 7)
     (and rvc rvb #xff)
     (cmp rvc #x20)
     (if (mi set! rvc 1)
	 (pl sub rvc rvc 31))
     (cmp rvc 96)
     (if (pl set! rvc 1))
     (ldr sv3 sv4 lsl rvc 2)
     ;; set char start pixel x
     (set! rvb #x20)
     (cdar sv4 sv2)
     (vcrfi rvc sv4 1)
     (bic rvc rvc #x03)
     (add rvc rvc lsr rvc 1)
     (add rvc rvc 1)
     (bl rvbcmd)
     ;; set char box x-start
     (set! rvb #x50)
     (bl rvbcmd)
     ;; set char box x-end
     (set! rvb #x51)
     (add rvc rvc 4)
     (bl rvbcmd)
     ;; set char start pixel y
     (set! rvb #x21)
     (cdar sv4 sv2)
     (vcrfi rva sv4 0)
     (bic rvc rva #x03)
     (add rvc rvc lsr rvc 1)
     (add rvc rvc lsr rva 2)
     (add rvc rvc 1)
     (bl rvbcmd)
     ;; set char box y-start
     (set! rvb #x52)
     (bl rvbcmd)
     ;; set char box y-end
     (set! rvb #x53)
     (add rvc rvc 5)
     (bl rvbcmd)
     ;; clear character box
     (set! rvb #x22)
     (cdar sv4 sv2)
     (vcrfi rvc sv4 5)
     (lsr rvc rvc 2)
     (orr rvc rvc #x1d0000)
     (bl rvbcmd)
     ;; write font pixels
     dspbl0
     (eq? sv3 $i0)
     (if (eq b dspxit))
     (set! rvb #x22)
     (cdar sv4 sv2)
     (cmp sv3 0)
     (if (pl vcrfi rvc sv4 5)
	 (mi vcrfi rvc sv4 4))
     (int->raw rvc rvc)
     (bl rvbcmd)
     (lsl sv3 sv3 1)
     (eor sv3 sv3 #x03)
     (b dspbl0)
     ;; restore the screen write box and exit via rvbcmd
     dspxit
     (set! rvb #x50)
     (set! rvc 0)
     (bl rvbcmd)
     (set! rvb #x52)
     (bl rvbcmd)
     (set! rvb #x51)
     (set! rvc 239)
     (bl rvbcmd)
     (set! rvb #x53)
     (add rvc rvc 80)
     (orr lnk sv5 $i0)
     ;; jump to write command in rvb (called with bl)
     rvbcmd
     (cdr sv4 sv2)
     (vcrfi rva sv4 6)
     (add rva rva 4)
     (set! pc rva))))

; resulting code vector (vcod):
vcod ; ->
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
	 151 70 0 191 0 0 0 0 0 0 0 0 0 0)


; -------------------------------------------------------------------
; scrlup:	scroll the display up
; -------------------------------------------------------------------
; on entry:	sv2 <- full output port
; modifies:	rva, rvb, rvc, sv4, sv5
; -------------------------------------------------------------------

(define vcod
  (assemble
   'var 0
   '((bic sv5 lnk $i0)
     ;; identify how to set scroll
     (cdar sv4 sv2)
     (vcrfi rvc sv4 0)
     (eq? rvc #xB5)
     (if (eq set! rvc $i0))
     (vcsti sv4 0 rvc)
     (add rvc rvc 4)
     (vcsti sv4 3 rvc)
     ;; perform scroll
     (set! rvb #x6A)
     (bic rva rvc #x03)
     (set! rvc rva)
     (add rvc rvc lsr rvc 1)
     (add rvc rvc lsr rva 2)
     (bl rvbcmd)
     ;; set pixel x
     (set! rvb #x20)
     (set! rvc 0)
     (bl rvbcmd)
     ;; set pixel y
     (set! rvb #x21)
     (cdar sv4 sv2)
     (vcrfi rva sv4 0)
     (bic rvc rva #x03)
     (add rvc rvc lsr rvc 1)
     (add rvc rvc lsr rva 2)
     (add rvc rvc 1)
     (bl rvbcmd)
     ;; clear screen bottom and return
     (set! rvb #x22)
     (cdar sv4 sv2)
     (vcrfi rvc sv4 5)
     (lsr rvc rvc 2)
     (orr rvc rvc #x00ff0000)
     (orr rvc rvc #x0E000000)
     (orr lnk sv5 $i0)
     ;; jump to write command in rvb (called with bl)
     rvbcmd
     (cdr sv4 sv2)
     (vcrfi rva sv4 6)
     (add rva rva 4)
     (set! pc rva))))

; resulting code vector (vcod):
vcod ; ->
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


; -------------------------------------------------------------------
; pixel:	scheme function
; -------------------------------------------------------------------
; on entry:	sv1 <- x coordinate (scheme int)
; on entry:	sv2 <- y coordinate (scheme int)
; on entry:	sv3 <- 16-bit color (scheme int)
; on exit:	sv1 <- '()
; -------------------------------------------------------------------

; (pixel x y col)
(define
  vcod
  (assemble
   'var 3               ; sv1 <- x, sv2 <- y, sv3 <- col
   '(;; get address of lcdcmd from port model
     (ldr sv4 lcd_pm)          ; sv4 <- port-model
     (vcrfi sv5 sv4 2)         ; sv5 <- output-port vector
     (vcrfi sv5 sv5 6)         ; sv5 <- address of lcdcmd
     ;; set x
     (set! rvb #x20)
     (int->raw rvc sv1)	; rvc <- x (raw int)
     (and rvc rvc #xff)
     (bl wcmd)
     ;; set y
     (set! rvb #x21)
     (int->raw rvc sv2)	; rvc <- y (raw int)
     (set! rva #xff)
     (orr rva rva #x100)
     (and rvc rvc rva)
     (bl wcmd)
     ;; set color
     (set! rvb #x22)
     (int->raw rvc sv3)	; rvc <- color (raw int)
     (set! rva #xff)
     (orr rva rva #xff00)
     (and rvc rvc rva)
     (set! sv1 $null)	; sv1 <- '() = return value
     (set! lnk cnt)     ; lnk <- return address for jump to lcdcmd
     ;; write command and data
     wcmd
     (add rva sv5 4)	; rva <- start address of lcdcmd primitive
     (set! pc rva)	; jump to lcdcmd
     ;; storage space
     lcd_pm  (0 . 0))))		; hole for port-model

; resulting code
vcod ; ->
#vu8(223 3 0 0
	 223 248 84 112 215 248 12 128 216 248 28 128 79 240
	 32 3 79 234 164 12 12 240 255 12 0 240 26 248 79 240
	 33 3 79 234 165 12 79 240 255 2 66 244 128 114 12 234
	 2 12 0 240 14 248 79 240 34 3 79 234 166 12 79 240
	 255 2 66 244 127 66 12 234 2 12 79 240 15 4 79 234
	 1 14 8 241 4 2 151 70 0 191 0 0 0 0 0 0 0)


; -------------------------------------------------------------------
; fill:		scheme function
; -------------------------------------------------------------------
; on entry:	sv1 <- x-top-left coordinate 			(scheme int)
; on entry:	sv2 <- y-top-left coordinate 			(scheme int)
; on entry:	sv3 <- (x-bot-right y-bot-right 16-bit-color)	(list of scheme int)
; on exit:	sv1 <- '()
; -------------------------------------------------------------------

; (fill x1 y1 x2 y2 col)
(define
  vcod
  (assemble
   'var 2
   '(;; get address of lcdcmd from port model
     (ldr sv4 lcd_pm)
     (vcrfi sv5 sv4 2)
     (vcrfi sv5 sv5 6)
     ;; set x, y, x1, y1
     (set! rvb #x20)
     (int->raw rvc sv1)
     (bl xwcmd)
     (set! rvb #x21)
     (int->raw rvc sv2)
     (bl ywcmd)
     (set! rvb #x50)
     (int->raw rvc sv1)
     (bl xwcmd)
     (set! rvb #x52)
     (int->raw rvc sv2)
     (bl ywcmd)
     ;; set x2 (and calculate repeat count = (x2 - x1 + 1)*(y2 - y1 + 1))
     (int->raw rva sv1)
     (snoc! sv1 sv3 sv3)
     (int->raw rvc sv1)
     (sub rva rvc rva)
     (add rva rva 1)
     (int->raw rvb sv2)
     (snoc! sv2 sv3 sv3)
     (int->raw rvc sv2)
     (sub rvb rvc rvb)
     (add rvb rvb 1)
     (mul rva rva rvb)
     (set! rvb #x51)
     (int->raw rvc sv1)
     (raw->int sv1 rva)   ; sv1 <- repeat count
     (bl xwcmd)
     ;; set y2
     (set! rvb #x53)
     (int->raw rvc sv2)
     (bl ywcmd)
     ;; set color + repeat count
     (car sv3 sv3)
     (lsl rva sv3 14)
     (lsr sv3 rva 14)
     filop
     (cmp sv1 #x20000)
     (if (mi b filast))
     (set! rvb #x22)
     (int->raw rvc sv3)
     (set! rva #x8000)
     (sub rva rva 1)
     (orr rvc rvc lsl rva 16)
     (bl wcmd)
     (sub sv1 sv1 #x20000)
     (b filop)
     filast
     (int->raw rva sv1)
     (eq? rva 0)
     (if (eq b done))
     (sub rva rva 1)
     (int->raw rvc sv3)
     (orr rvc rvc lsl rva 16)
     (set! rvb #x22)
     (bl wcmd)
     ;; restore box to (0,0)-(239,319) and return
     done
     (set! rvb #x50)
     (set! rvc 0)
     (bl xwcmd)
     (set! rvb #x52)
     (bl ywcmd)
     (set! rvb #x51)
     (set! rvc 239)
     (bl xwcmd)
     (set! rvb #x53)
     (add rvc rvc 80)
     (set! sv1 $null)
     (set! lnk cnt)
     ;; write command and data
     ywcmd
     (set! rva #xff)
     (orr rva rva #x100)
     (and rvc rvc rva)
     wcmd
     (add rva sv5 4)
     (set! pc rva)
     xwcmd
     (and rvc rvc #xff)
     (b wcmd)
     ;; storage space
     lcd_pm  (0 . 0))))

; resulting code
vcod ; ->
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
	 248 191 0 0 0 0 0 0 0 0 0 0 0 0 0 0)


; -------------------------------------------------------------------
; u16w:		write 16-bit value to address #x06000000 (i.e. LCD)
; -------------------------------------------------------------------
; on entry:	sv1 <- value to write (scheme int)
; on exit:	sv1 <- #t
; -------------------------------------------------------------------

(define
  vcod
  (assemble
   'var 1
   '((int->raw rvb sv1)
     (set! rva #x6)
     (lsl rva rva 28)
     (strh rvb rva)
     (set! sv1 $t)
     (set! pc cnt))))

; resulting code
vcod ; ->
#vu8(223 1 0 0
	 79 234 164 3 79 240 6 2 79 234 2 114 162 248
	 0 48 79 240 31 4 143 70 0 191 0)

