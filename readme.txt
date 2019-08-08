Small pure Prolog intepreter in Elixir.
Project is called Elxlog.
Goal: Fusion of Elixir and Prolog

invoke:
  mix elxlog

quit: halt.

builtin:
  atom/1
  atomic/1
  integer/1
  float/1
  number/1
  var/1
  nonvar/1
  true/0
  fail/0
  write/1
  nl/0
  reconsult/1  (['filename.pl'])
  assert/1
  is/2
  =/2
  </2
  >/2
  =>/2
  =</2
  halt/0
  listing/0
  elixir/1  Run the Elixir code. See function.ex (e.g. elixir(elx_in_the_park()) )
formula:
  +,^,*,/,^
  prefix "elx_" means Elixir function. See function.ex

Example:
mix prolog
Compiling 1 file (.ex)
Prolog in Elixir
?- assert(fact(0,1)).
true
?- assert((fact(N,A) :- N1 is N-1,fact(N1,A1),A is N*A1)).
true
?- fact(10,X).
X = 3628800
true
?-

?- assert(likes(kim,robin)).
true
?- assert(likes(sandy,lee)).
true
?- assert(likes(sandy,kim)).
true
?- assert(likes(robin,cats)).
true
?- assert((likes(sandy,X) :- likes(X,cats))).
true
?- assert((likes(kim,X) :- likes(X,lee),likes(X,kim))).
true
?- assert(likes(X,X)).
true
?- listing.
likes(kim,robin)
likes(sandy,lee)
likes(sandy,kim)
likes(robin,cats)
likes(sandy,X) :- likes(X,cats)
likes(kim,X) :- likes(X,lee)likes(X,kim)
likes(X,X)
true
?- likes(sandy,Who).
Who = lee;
Who = kim;
Who = robin;
Who = sandy;
Who = cats;
Who = sandy;
false

?- assert(append([], Xs, Xs)).
true
?- assert((append([X | Ls], Ys, [X | Zs]) :- append(Ls, Ys, Zs))).
true
?- append(X,Y,[1,2,3]).
X = []
Y = [1,2,3];
X = [1]
Y = [2,3];
X = [1,2]
Y = [3];
X = [1,2,3]
Y = [];
false

?-halt.
goodbye
