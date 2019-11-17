%test
fact(0,1).
fact(N,A) :- N1 is N-1,fact(N1,A1),A is N*A1.

my_member(X, [X|_]).
my_member(X, [_|Y]) :- my_member(X, Y).

likes(kim,robin).
likes(sandy,lee).
likes(sandy,kim).
likes(robin,cats).
likes(sandy,X) :- likes(X,cats).
likes(kim,X) :- likes(X,lee),likes(X,kim).
likes(X,X).


tarai(X,Y,Z,A) :- A is elx_tarai(X,Y,Z).

ack(M,N,A) :- A is elx_ack(M,N).

qsort([],[]).
qsort([X],[X]).
qsort([X|Xs],Y) :-
  part(X,Xs,S,L),qsort(S,S1),qsort(L,L1),append(S1,L1,Y).


part(A,[],     [A],[]).
part(A,[X|Xs],S0,L) :- A>=X,S0=[X|S], part(A,Xs,S,L).
part(A,[X|Xs],S,L0) :- A < X,L0=[X|L], part(A,Xs,S,L).




!elixir
defmodule Elxfunc do
  def ack(0, n), do: n + 1
  def ack(m, 0), do: ack(m - 1, 1)
  def ack(m, n), do: ack(m - 1, ack(m, n - 1))

  def tarai(x, y, z) do
    cond do
      x <= y -> y
      true -> tarai(tarai(x - 1, y, z), tarai(y - 1, z, x), tarai(z - 1, x, y))
    end
  end

end
