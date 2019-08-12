%test
fact(0,1).
fact(N,A) :- N1 is N-1,fact(N1,A1),A is N*A1.

likes(kim,robin).
likes(sandy,lee).
likes(sandy,kim).
likes(robin,cats).
likes(sandy,X) :- likes(X,cats).
likes(kim,X) :- likes(X,lee),likes(X,kim).
likes(X,X).

append([], Xs, Xs).
append([X | Ls], Ys, [X | Zs]) :- append(Ls, Ys, Zs).

tarai(X,Y,Z,A) :- A is elx_tarai(X,Y,Z).

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

  def in_the_park() do
    if :rand.uniform(2) == 1 do
      IO.puts("woof")
    else
      IO.puts("ruff")
    end
    in_the_park()
  end

end
