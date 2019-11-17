# Elxlog

Small pure Prolog intepreter in Elixir.
Project is called Elxlog.
Goal is fusion of Elixir and Prolog

## caution
 - predicate with zero arity is written like this.
 - e.g. halt()  true()  fail()

 - float number is same as ISO-Prolog e.g. 3.0e4

 - comma and period is delimiter. Not operator.

 - The comparison operation is the same as C and Elixir.
 e.g. < > >= <= == !=

 - Anonymous variables in the same clause are not distinguished.

 - Elixir code can be mixed in the file read by reconsult/1.
 The line after "!Elixir" is Elixir code. see test.pl

 - There is no higher-order predicate such as call/1 assert/1 once/1.
 Within first order predicate logic.

## invoke

  mix elxlog

## quit

 halt().

## builtin
```
  append/3
  atom/1
  atomic/1
  between/3
  elixir/1  Run the Elixir code. See test.pl (e.g. elixir(elx_in_the_park()) )
  float/1
  fail/0
  halt/0
  integer/1
  is/2
  length/2
  listing/1
  member/2
  name/2
  nl/0
  nonvar/1
  not/1
  number/1
  read/1
  reconsult/1  (or ['filename.pl'])
  time/1
  true/0
  var/1
  write/1
  =/2
  </2
  >/2
  >=/2
  <=/2
  !=/2
  ==/2
  =../2

formula:
  +,^,*,/,^
  prefix "elx_" means Elixir function. See test.pl
```

## Example
```
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
```
# compiler
under construction

```
Elxlog ver0.12
?- compile('test.pl').
true
?- ['test.o'].
true
?- my_member(2,[1,2,3]).
true
?- fact(10,X).
X = 3628800.
true
?-
```
