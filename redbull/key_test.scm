; combine 4 keys with 4 led-toggle functions

(if (not (defined?  'key-wakeup-hook))
    (define key-wakeup-hook  (lambda () (led-toggle 0))))
(if (not (defined?  'key-tamper-hook))
    (define key-tamper-hook (lambda () (led-toggle 1))))
(if (not (defined?  'key-user1-hook))
    (define key-user1-hook (lambda () (led-toggle 2))))
(if (not (defined?  'key-user2-hook))
    (define key-user2-hook (lambda () (led-toggle 3))))

; fsm-key structure:
; (cons (cons STATE INTERNAL-COUNTER) (cons KEY-SCAN-PROC KEY-HOOK-PROC))
(define fsm-key-wakeup (cons (cons 0 0)
                             (cons key-wakeup-pressed? key-wakeup-hook)))
(define fsm-key-tamper (cons (cons 0 0)
                             (cons key-tamper-pressed? key-tamper-hook)))
(define fsm-key-user1  (cons (cons 0 0)
                             (cons key-user1-pressed? key-user1-hook)))
(define fsm-key-user2  (cons (cons 0 0)
                             (cons key-user2-pressed? key-user2-hook)))

; FSM update proc per 10ms
(define (fsm-key-update fsm-key)
  (let* ((state (caar fsm-key))
         (counter (cdar fsm-key))
         (pressed? ((cadr fsm-key))))
        ;(display state)
        (cond ((= state 0)  ; key released
               (if pressed?
                (begin
                  (set! state 1)
                  (set! counter 0))))
              ((= state 1)  ; key pressed, check for voltage stability
               (if pressed?
                   (if (> counter 5)  ; wait for 50ms for stability
                     (begin
                       (set! state 2)
                       ((cddr fsm-key))) ; key pressed, function here
                     (set! counter (+ counter 1)))
                   (set! state 0)))
              ((= state 2)  ; key pressed
               (if (not pressed?)
                   (begin
                     (set! state 3)
                     (set! counter 0))))
              (else  ; function frozen for a short while
               (if (> counter 10)  ; function frozen for 100ms
                   (set! state 0)
                   (set! counter (+ counter 1)))))
        (set-car! fsm-key (cons state counter))))  ; update in place


(define (fsm-keys-loop)
  (fsm-key-update fsm-key-wakeup)
  (fsm-key-update fsm-key-tamper)
  (fsm-key-update fsm-key-user1)
  (fsm-key-update fsm-key-user2)
  (loop-ms 10)
  (led-toggle 4)  ; LED indicator
  (fsm-keys-loop))

(fsm-keys-loop)

