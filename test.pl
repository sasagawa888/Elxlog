assert(fact(0,1)).
assert((fact(N,A) :- N1 is N-1,fact(N1,A1),A is N*A1)).

assert(likes(kim,robin)).
assert(likes(sandy,lee)).
assert(likes(sandy,kim)).
assert(likes(robin,cats)).
assert((likes(sandy,X) :- likes(X,cats))).
assert((likes(kim,X) :- likes(X,lee),likes(X,kim))).
assert(likes(X,X)).

assert(append([], Xs, Xs)).
assert((append([X | Ls], Ys, [X | Zs]) :- append(Ls, Ys, Zs))).
