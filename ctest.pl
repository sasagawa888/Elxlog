fact(0,1).
fact(N,A) :- N1 is N-1,fact(N1,A1),A is N*A1.
