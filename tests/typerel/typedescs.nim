# bug #1774
proc p(T: typedesc) = discard

p(typeof((5, 6)))       # Compiles
(typeof((5, 6))).p      # Doesn't compile (SIGSEGV: Illegal storage access.)
type T = typeof((5, 6)) # Doesn't compile (SIGSEGV: Illegal storage access.)
