defmodule Elxlog do
  def repl() do
    IO.puts("Elxlog ver0.07")
    repl1([])
  end

  defp repl1(def) do
    try do
      IO.write("?- ")
      {s,_} = Read.parse([],:stdin)
      s1 = add_ask(s)
      {s2,_,def1} = Prove.prove_all(s1,[],def,1)
      Print.print(s2)
      repl1(def1)
    catch
      x -> IO.puts(x)
      if x != "goodbye" do
        repl1(def)
      else
        true
      end
    end
  end

  def find_var(x) do
    find_var1(x,[]) |> unique() |> Enum.reverse()
  end

  def find_var1([],res) do res end
  def find_var1(x,res) when is_number(x) do res end
  def find_var1(x,res) when is_atom(x) do
    if is_var(x) && !Enum.member?(res,x) do
      [x|res]
    else
      res
    end
  end
  def find_var1([x|xs],res) when is_list(x) do
    res1 = find_var1(x,[])
    find_var1(xs,res1++res)
  end
  def find_var1([x|xs],res) do
    if is_var(x) && !Enum.member?(res,x) do
      find_var1(xs,[x|res])
    else
      find_var1(xs,res)
    end
  end

  def unique([]) do [] end
  def unique([x|xs]) do
    if Enum.member?(xs,x) do
      unique(xs)
    else
      [x|unique(xs)]
    end
  end

  def add_ask(x) do
    ask = [:builtin,[:ask|find_var(x)]]
    if is_assert(x) do
      [x]
    else if is_pred(x) || is_builtin(x) do
      [x] ++ [ask]
    else
      # conjunction
      x ++ [ask]
    end
    end
  end

  #-------------data type------------
  def is_pred([:pred,_]) do true end
  def is_pred(_) do false end

  def is_clause([:clause,_,_]) do true end
  def is_clause(_) do false end

  def is_builtin([:builtin,_]) do true end
  def is_builtin(_) do false end

  def is_formula([:formula,_]) do true end
  def is_formula(_) do false end

  def  is_var(x) do
    if (is_atomvar(x) && !is_anonymous(x)) || is_variant(x) do
      true
    else
      false
    end
  end
  # atom vairable
  def is_atomvar(x) when is_atom(x) do
    x1 = x |> Atom.to_charlist |> Enum.at(0)
    cond do
      x1 == 95 -> true  #under bar
      x1 >= 65 && x1 <= 90 -> true #uppercase
      true -> false
    end
  end
  def is_atomvar(_) do false end

  def is_anonymous(:_) do true end
  def is_anonymous({:_,_}) do true end
  def is_anonymous(_) do false end

  # variant variable
  def is_variant({x,y}) when is_integer(y) do
    if is_atomvar(x) do
      true
    else
      false
    end
  end
  def is_variant(_) do false end

  # assert builtin
  def is_assert([:builtin,[:assert|_]]) do true end
  def is_assert(_) do false end

  #for debug
  def stop() do
    raise "debug stop"
  end

end
