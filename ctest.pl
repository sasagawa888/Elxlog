fact(0,1).
fact(N,A) :- N1 is N-1,fact(N1,A1),A is N*A1.

my_member(X, [X|_]).
my_member(X, [_|Y]) :- my_member(X, Y).

test() :- queen([1,2,3,4,5,6,7,8],X),write(X),nl(),fail().

queen(Data, Out) :-
	queen_2(Data, [], Out).

queen_2([], _, []).
queen_2([H|T], History, [Q|M]) :-
	qdelete(Q, H, T, L1),
	nodiag(History, Q, 1),
	queen_2(L1, [Q|History], M).



qdelete(A, A, L, L).
qdelete(X, A, [H|T], [A|R]) :-
	qdelete(X, H, T, R).


nodiag([], _, _).
nodiag([N|L], B, D) :-
	D != N - B,
	D != B - N,
	D1 is D + 1,
	nodiag(L, B, D1).
