(if (member "init.scm" (files)) (load "init.scm"))
(if (member "board.scm" (files))  (load "board.scm"))
;(if (member '(hal) (libs)) (import (hal)))
;(if (defined? 'hal-init) (hal-init))
(if (member "autorun.scm" (files)) (load "autorun.scm"))

