(define (cat file)
  (let ((port (open-input-file file)))
    (if (zero? port) #f
      (let loop ((val (read port)))
        (if (eof-object? val)
          (close-input-port port)
          (begin
            (if (not (vector? val))
              (write val)
              (begin
                (write (vector-length val))
                (write (vector-ref val 0))
                (write (vector-ref val (- (vector-length val) 1)))))
            (newline)
            (loop (read port))))))))
 
