Small pure Prolog intepreter in Elixir.
Project is called Elxlog.
Goal: Fusion of Elixir and Prolog

caution:
 predicate with zero arity is written like this:
 e.g. halt()  true()  fail()

 float number is same as ISO-Prolog e.g. 3.0e4

 comma and period is delimiter. Not operator.

 The comparison operation is the same as C and Elixir.
 e.g. < > >= <= == !=

 Elixir code can be mixed in the file read by reconsult/1.
 The line after "!Elixir" is Elixir code. see test.pl

invoke:
  mix elxlog

quit: halt().

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
  not/1
  write/1
  nl/0
  reconsult/1  (['filename.pl'])
  assert/1
  asserta/1
  assertz/1
  between/3
  is/2
  length/2
  =/2
  </2
  >/2
  >=/2
  <=/2
  !=/2
  ==/2
  =../2
  halt/0
  listing/0
  listing/1
  elixir/1  Run the Elixir code. See test.pl (e.g. elixir(elx_in_the_park()) )
formula:
  +,^,*,/,^
  prefix "elx_" means Elixir function. See test.pl

Example:
mix prolog
Compiling 1 file (.ex)
Elxlog ver0.XX
?- ['test.pl'].
true
?- listing().
fact(0,1)
fact(N,A) :- is(N1,N-1),fact(N1,A1),is(A,N*A1).
likes(kim,robin)
likes(sandy,lee)
likes(sandy,kim)
likes(robin,cats)
likes(sandy,X) :- likes(X,cats).
likes(kim,X) :- likes(X,lee),likes(X,kim).
likes(X,X)
append([],Xs,Xs)
append([X,|Ls],Ys,[X,|Zs]) :- append(Ls,Ys,Zs).
bet(N,M,K) :- =<(N,M),=(K,N).
bet(N,M,K) :- <(N,M),is(N1,N+1),bet(N1,M,K).
true
?- X is elx_ack(3,11).
X = 16381
true
?- fact(10,X).
X = 3628800
true
?- likes(sandy,Who).
Who = lee;
Who = kim;
Who = robin;
Who = sandy;
Who = cats;
Who = sandy;
false
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
?- halt().
goodbye
