; morse code test

(define morse-code-table 
  (list
    (list #\a  ".-")
    (list #\b  "-...")
    (list #\c  "-.-.")
    (list #\d  "-..")
    (list #\e  ".")
    (list #\f  "..-.")
    (list #\g  "--.")
    (list #\h  "....")
    (list #\i  "..")
    (list #\j  ".---")
    (list #\k  "-.-")
    (list #\l  ".-..")
    (list #\m  "--")
    (list #\n  "-.")
    (list #\o  "---")
    (list #\p  ".--.")
    (list #\q  "--.-")
    (list #\r  ".-.")
    (list #\s  "...")
    (list #\t  "-")
    (list #\u  "..-")
    (list #\v  "...-")
    (list #\w  ".--")
    (list #\x  "-..-")
    (list #\y  "-.--")
    (list #\z  "--..")
    (list #\0  "-----")
    (list #\1  ".----")
    (list #\2  "..---")
    (list #\3  "...--")
    (list #\4  "....-")
    (list #\5  ".....")
    (list #\6  "-....")
    (list #\7  "--...")
    (list #\8  "---..")
    (list #\9  "----.")
    (list #\/  "-..-.")
    (list #\+  ".-.-.")
    (list #\=  "-...-")
    (list #\.  ".-.-.-")
    (list #\" "--..--")
    (list #\?  "..--..")
    (list #\(  "-.--.")
    (list #\)  "-.--.-")
    (list #\-  "-....-")
    (list #\"  ".-..-.")
    (list #\_  "..--.-")
    (list #\'  ".----.")
    (list #\" "---...")
    (list #\;  "-.-.-.")
    (list #\$  "...-..-")
    (list #\&  ".-...")
    (list #\@  ".--.-.")
  ))


(define (driver-init)
  (xport-dir-out 0)
  (xport-clear 0))

(define (driver-set)
  (xport-set 0))

(define (driver-clear)
  (xport-clear 0))

(driver-init)

(define dot-ms  50)

(define dash-ms  (* dot-ms 3))

(define pause-ms  dot-ms)

(define (find-code-string table code)
  (if (zero? (length table))
      ""  ; not found
      (let ((head (car table)))
           (if (char=? (car head) code)
               (list-ref head 1)
               (find-code-string (cdr table) code)))))

(define (drive-code code)
  (driver-set)
  (loop-ms (if (char=? code #\.) dot-ms  dash-ms))
  (driver-clear)
  (loop-ms pause-ms))

(define (send-morse-char chr)
  (for-each drive-code
     (string->list (find-code-string morse-code-table chr))))

(define (send-morse-string str)
  (for-each (lambda (chr) (send-morse-char chr) (display chr))
    (string->list str)))



(send-morse-string "sos")
;(send-morse-string "abcdefghijklmnopqstuvwxyz")
;(send-morse-string "0123456789")
