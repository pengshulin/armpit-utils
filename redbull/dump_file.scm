; dump file function

(define (dump-file filename)
  (let ((port (open-input-file filename))
        (counter 0))
       (let display-hex-char ((obj (read port))
           (if (eof-object? obj)
               #t
               (  
