#----------------print------------
defmodule Print do
  def print(x) do
    print1(x)
    IO.puts("")
  end

  def print1(x) when is_number(x) do
    IO.write(x)
  end
  def print1(x) when is_atom(x) do
    if x != nil do
      IO.write(x)
    else
      IO.write("nil")
    end
  end
  def print1(x) when is_list(x) do
    cond do
      Elxlog.is_pred(x) -> print_pred(x)
      Elxlog.is_builtin(x) -> print_pred(x)
      Elxlog.is_clause(x) -> print_clause(x)
      Elxlog.is_formula(x) -> print_formula(x)
      true -> print_list(x)
    end
  end



  def print_pred([_,[name|args]]) do
    IO.write(name)
    print_tuple(args)
  end

  def print_clause([_,head,body]) do
    print_pred(head)
    IO.write(" :- ")
    print_body(body)
  end

  def print_body([]) do true end
  def print_body([x]) do
    print_pred(x)
    IO.write(".")
  end
  def print_body([x|xs]) do
    print_pred(x)
    IO.write(",")
    print_body(xs)
  end

  def print_formula([:formula,x]) do
    print_formula1(x)
  end

  def print_formula1([]) do true end
  def print_formula1(x) when is_number(x) do
    IO.write(x)
  end
  def print_formula1(x) when is_atom(x) do
    IO.write(x)
  end
  def print_formula1([f,o1,o2]) do
    print_formula1(o1)
    IO.write(f)
    print_formula1(o2)
  end

  def print_list([]) do
    IO.write("[]")
  end
  def print_list([x|xs]) do
    IO.write("[")
    print1(x)
    if xs != [] do
      IO.write(",")
    end
    print_list1(xs)
  end

  defp print_list1(x) when is_atom(x)do
    IO.write("|")
    print1(x)
    IO.write("]")
  end
  defp print_list1(x) when is_number(x)do
    IO.write("|")
    print1(x)
    IO.write("]")
  end
  defp print_list1([]) do
    IO.write("]")
  end
  defp print_list1([x|xs]) do
    print1(x)
    if xs != [] && !is_atom(xs) && !is_number(xs) do
      IO.write(",")
    end
    print_list1(xs)
  end

  defp print_tuple([]) do
    IO.write("()")
  end
  defp print_tuple([x|xs]) do
    IO.write("(")
    print1(x)
    if xs != [] do
      IO.write(",")
    end
    print_tuple1(xs)
  end
  defp print_tuple1([]) do
    IO.write(")")
  end
  defp print_tuple1([x|xs]) do
    print1(x)
    if xs != [] do
      IO.write(",")
    end
    print_tuple1(xs)
  end

  def print_debug(x) do
    print_debug1(x)
    IO.puts("")
  end

  def print_debug1(x) when is_number(x) do
    IO.write(x)
  end
  def print_debug1(x) when is_atom(x) do
    if x != nil do
      IO.write(":")
      IO.write(x)
    else
      IO.write("nil")
    end
  end
  def print_debug1(x) when is_list(x) do
    print_debug_list(x)
  end

  def print_debug_list([]) do
    IO.write("[]")
  end
  def print_debug_list([x|xs]) do
    IO.write("[")
    print_debug1(x)
    if xs != [] && !is_atom(xs) && !is_atom(xs) do
      IO.write(",")
    end
    print_debug_list1(xs)
  end

  defp print_debug_list1(x) when is_atom(x)do
    IO.write("|")
    print_debug1(x)
    IO.write("]")
  end
  defp print_debug_list1(x) when is_number(x)do
    IO.write("|")
    print_debug1(x)
    IO.write("]")
  end
  defp print_debug_list1([]) do
    IO.write("]")
  end
  defp print_debug_list1([x|xs]) do
    print_debug1(x)
    if xs != [] do
      IO.write(",")
    end
    print_debug_list1(xs)
  end

end
