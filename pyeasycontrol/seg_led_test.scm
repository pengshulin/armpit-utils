; test 7-segment LED
(define inv #t)

(define pin-g 0)
(define pin-e 1)
(define pin-f 2)
(define pin-d 3)
(define pin-com1 4)
(define pin-com2 5)
(define pin-a 6)
(define pin-c 7)
(define pin-b 8)
(define pin-dot 9)

(define list-all-pins 
  (map eval '(pin-a pin-b pin-c pin-d pin-e pin-f pin-g pin-dot)))

(define segment-tab
  '((pin-a pin-b pin-c pin-d pin-e pin-f      )
    (      pin-b pin-c                        )
    (pin-a pin-b       pin-d pin-e       pin-g)
    (pin-a pin-b pin-c pin-d             pin-g)
    (      pin-b pin-c             pin-f pin-g)
    (pin-a       pin-c pin-d       pin-f pin-g)
    (pin-a       pin-c pin-d pin-e pin-f pin-g)
    (pin-a pin-b pin-c                        )
    (pin-a pin-b pin-c pin-d pin-e pin-f pin-g)
    (pin-a pin-b pin-c pin-d       pin-f pin-g)))


(define (get-list-item lst id)
  (if (zero? id)
      (car lst)
      (get-list-item (cdr lst) (- id 1))))


(xport-dir-out-all)

(for-each (if inv xport-set xport-clear) list-all-pins)
(for-each (if inv xport-set xport-clear) (map eval '(pin-com1 pin-com2)))

(define (display-number number)
  (let ((segs-on (map eval (get-list-item segment-tab number))))
       (for-each (lambda (pin) 
                         (if (member pin segs-on)
                             ((if inv xport-clear xport-set) pin)
                             ((if inv xport-set xport-clear) pin)))
                 list-all-pins)))

(define (loop-display-numbers ms)
   (for-each (lambda (number)
                     (display-number number)
                     (loop-ms ms))
             '(0 1 2 3 4 5 6 7 8 9))
   (loop-display-numbers ms)) 


(loop-display-numbers 500)


