; configure pin as push-pull
(config-pin gioc 2 #b00 #b10)

; in autorun mode

(define key-wakeup-hook (lambda () (begin (pin-set gioc 2) (loop-ms 100) (pin-clear gioc 2))))
(define key-tamper-hook (lambda () (begin (if (pin-set? gioc 2) (pin-clear gioc 2) (pin-set gioc 2)))))
;(define key-user1-hook (lambda () ()))
;(define key-user2-hook (lambda () ()))


(load "key_test.scm")



