# ---------------read----------------------------------
defmodule Read do
  # lowercase or number char or underbar
  def is_atom_str(x) do
    y = String.to_charlist(x)

    if hd(y) >= 97 && hd(y) <= 122 &&
         Enum.all?(y, fn z -> (z >= 97 && z <= 122) || (z >= 48 && z <= 57) || z == 95 end) do
      true
    else
      false
    end
  end

  @doc """
  iex> Read.is_builtin_str("halt")
  true
  iex> Read.is_builtin_str("halz")
  false
  """
  def is_builtin_str(x) do
    Enum.member?(
      [
        "halt",
        "write",
        "nl",
        "is",
        "listing",
        "ask",
        "debug",
        "trace",
        "notrace",
        "atom",
        "atomic",
        "integer",
        "float",
        "number",
        "reconsult",
        "var",
        "nonvar",
        "elixir",
        "true",
        "fail",
        "between",
        "not",
        "length",
        "time",
        "append",
        "functor",
        "arg",
        "name",
        "read",
        "member",
        "compile",
        "parallel",
        ":-",
        ">",
        "<",
        "=>",
        "=<",
        "=..",
        "==",
        "!=",
        "="
      ],
      x
    )
  end

  def is_func_str(x) do
    Enum.member?(["+", "-", "*", "/", "^"], x)
  end

  @doc """
  if prefix of str is elx_ it is Elixir function fname
  iex> Read.is_elixir_func_str("elx_foo")
  true
  iex> Read.is_elixir_func_str("foo")
  false
  """
  def is_elixir_func_str(x) do
    if String.at(x, 0) == "e" && String.at(x, 1) == "l" && String.at(x, 2) == "x" &&
         String.at(x, 3) == "_" do
      true
    else
      false
    end
  end

  @doc """
  iex(1)> Read.elixir_name("elx_foo")
  "foo"
  """
  def elixir_name(x) do
    {_, name} = String.split_at(x, 4)
    name
  end

  @doc """
  if head charactor is upper case it is variable
  if head charactor is underbar it is variable
  iex> Read.is_var_str("A")
  true
  iex> Read.is_var_str("a")
  false
  """
  def is_var_str(x) do
    x1 = String.at(x, 0)

    Enum.member?(
      [
        "_",
        "A",
        "B",
        "C",
        "D",
        "E",
        "F",
        "G",
        "H",
        "I",
        "j",
        "K",
        "L",
        "M",
        "N",
        "O",
        "P",
        "Q",
        "R",
        "S",
        "T",
        "U",
        "V",
        "W",
        "X",
        "Y",
        "Z"
      ],
      x1
    )
  end

  def is_func_atom(x) do
    Enum.member?([:+, :-, :*, :/, :^], x)
  end

  def is_infix_builtin(x) do
    Enum.member?([:is, :=, :"=..", :==, :>=, :<=, :>, :<, :^, :==, :!=], x)
  end

  def parse(buf, stream) do
    {s1, buf1} = read(buf, stream)
    {s2, buf2} = read(buf1, stream)

    cond do
      s2 == :. ->
        cond do
          is_atom(s1) ->
            Elxlog.error("Error: parse expected () ", [s1])

          !Elxlog.is_pred(s1) && !Elxlog.is_builtin(s1) ->
            {[:builtin, [:reconsult | s1]], buf2}

          true ->
            {s1, buf2}
        end

      s2 == :":-" ->
        {s3, buf3} = parse1(buf2, [], stream)
        {[:clause, s1, s3], buf3}

      s2 == :"," ->
        {s3, buf3} = parse1(buf2, [s1], stream)
        {s3, buf3}

      is_infix_builtin(s2) ->
        {s3, buf3, status} = parse2([], [], buf2, stream)

        cond do
          status == :. -> {[:builtin, [s2, s1, s3]], buf3}
          status == :"," -> parse1(buf3, [[:builtin, [s2, s1, s3]]], stream)
          true -> Elxlog.error("Error: illegal delimiter ", [s3, status])
        end

      true ->
        Elxlog.error("Error: syntax error ", [s1, s2])
    end
  end

  def parse1(buf, res, stream) do
    {s1, buf1} = read(buf, stream)
    {s2, buf2} = read(buf1, stream)

    cond do
      s2 == :. ->
        {res ++ [s1], buf2}

      s2 == :")" ->
        {res ++ [s1], buf2}

      s2 == :"," ->
        if !Elxlog.is_pred(s1) && !Elxlog.is_builtin(s1) do
          Elxlog.error("Error: expected () ", [s1])
        end

        parse1(buf2, res ++ [s1], stream)

      is_infix_builtin(s2) ->
        {s3, buf3, status} = parse2([], [], buf2, stream)

        cond do
          status == :"," ->
            parse1(buf3, res ++ [[:builtin, [s2, s1, s3]]], stream)

          status == :. ->
            {res ++ [[:builtin, [s2, s1, s3]]], buf3}

          status == :")" ->
            {res ++ [[:builtin, [s2, s1, s3]]], buf3}
        end

      true ->
        Elxlog.error("Error illegal body ", [s1, s2])
    end
  end

  # parse formula
  # 1st arg operand list
  # 2nd arg operator list
  # 3rd arg buffer
  # 4th arg stream (:sidin or file)
  # return {value,buffer,last-token}
  def parse2([], [], buf, stream) do
    # IO.inspect binding()
    {s, buf1} = read(buf, stream)

    cond do
      s == :. -> Elxlog.error("Error: illegal formula1 ", [s])
      is_func_atom(s) -> parse2([], [s], buf1, stream)
      true -> parse2([s], [], buf1, stream)
    end
  end

  # minus number e.g. ["-", 2, ...] -> -2
  def parse2([], [:-], buf, stream) do
    {s, buf1} = read(buf, stream)

    if !is_number(s) do
      Elxlog.error("Error: illegal formula2 ", [s])
    end

    parse2([-1 * s], [], buf1, stream)
  end

  def parse2([o1], [], buf, stream) do
    # IO.inspect binding()
    {s, buf1} = read(buf, stream)

    cond do
      s == :. -> {o1, buf1, :.}
      s == :"," -> {o1, buf1, :","}
      s == :")" -> {o1, buf1, :")"}
      is_func_atom(s) -> parse2([o1], [s], buf1, stream)
      true -> Elxlog.error("Error: illegal formula3 ", [o1, s])
    end
  end

  def parse2([o1], [f1], buf, stream) do
    # IO.inspect binding()
    {s, buf1} = read(buf, stream)

    cond do
      s == :- ->
        {s1, buf2} = read(buf1, stream)
        parse2([-1 * s1, o1], [f1], buf2, stream)

      s == :"(" ->
        {[_, s1], buf2, term} = parse2([], [], buf1, stream)

        if term != :")" do
          Elxlog.error("Error: illegal formula paren", [s1])
        end

        parse2([s1, o1], [f1], buf2, stream)

      is_func_atom(s) ->
        Elxlog.error("Error: illegal formula4 ", [s])

      true ->
        parse2([s, o1], [f1], buf1, stream)
    end
  end

  def parse2([o1, o2], [f1], buf, stream) do
    # IO.inspect binding()
    {s, buf1} = read(buf, stream)

    cond do
      s == :. -> {[:formula, [f1, o2, o1]], buf1, :.}
      s == :"," -> {[:formula, [f1, o2, o1]], buf1, :","}
      s == :")" -> {[:formula, [f1, o2, o1]], buf1, :")"}
      is_func_atom(s) && weight(s) >= weight(f1) -> parse2([[f1, o2, o1]], [s], buf1, stream)
      is_func_atom(s) && weight(s) < weight(f1) -> parse2([o1, o2], [s, f1], buf1, stream)
      true -> Elxlog.error("Error: illegal formula5 ", [s])
    end
  end

  def parse2([o1, o2], [f1, f2], buf, stream) do
    # IO.inspect binding()
    {s, buf1} = read(buf, stream)

    cond do
      s == :. ->
        Elxlog.error("Error: illegal formula6 ", [f1, s])

      s == :- ->
        {s1, buf1} = read(buf1, stream)
        parse2([[f2, o2, [f1, o1, -1 * s1]]], [], buf1, stream)

      is_func_atom(s) ->
        Elxlog.error("Error: illegal formula7 ", [s])

      true ->
        parse2([[f2, o2, [f1, o1, s]]], [], buf1, stream)
    end
  end

  defp weight(:+) do
    100
  end

  defp weight(:-) do
    100
  end

  defp weight(:*) do
    50
  end

  defp weight(:/) do
    50
  end

  def read([], stream) do
    if stream == :stdin do
      buf = IO.gets("") |> tokenize(stream)
      read(buf, stream)
    else
      []
    end
  end

  def read(["" | xs], stream) do
    read(xs, stream)
  end

  def read(["." | xs], _) do
    {:., xs}
  end

  def read(["," | xs], _) do
    {:",", xs}
  end

  def read([")" | xs], _) do
    {:")", xs}
  end

  def read(["(" | xs], _) do
    {:"(", xs}
  end

  def read(["[" | xs], stream) do
    read_list(xs, [], stream)
  end

  def read([x, "(" | xs], stream) do
    # when x = +-*/^
    if is_func_str(x) do
      {String.to_atom(x), ["(" | xs]}
    # when predicate
    else
      {tuple, rest} = read_tuple(xs, [], stream)

      cond do
        is_builtin_str(x) -> {[:builtin, [String.to_atom(x) | tuple]], rest}
        is_func_str(x) -> {[String.to_atom(x) | tuple], rest}
        is_elixir_func_str(x) -> {[:func, [String.to_atom(elixir_name(x)) | tuple]], rest}
        true -> {[:pred, [String.to_atom(x) | tuple]], rest}
      end
    end
  end

  def read([x, "." | xs], _) do
    cond do
      is_var_str(x) -> {String.to_atom(x), ["." | xs]}
      is_integer_str(x) -> {String.to_integer(x), ["." | xs]}
      is_float_str(x) -> {String.to_float(x), ["." | xs]}
      true -> {String.to_atom(x), ["." | xs]}
    end
  end

  def read([x, "," | xs], _) do
    cond do
      is_atom_str(x) -> {String.to_atom(x), ["," | xs]}
      is_var_str(x) -> {String.to_atom(x), ["," | xs]}
      is_integer_str(x) -> {String.to_integer(x), ["," | xs]}
      is_float_str(x) -> {String.to_float(x), ["," | xs]}
      true -> {x, ["," | xs]}
    end
  end

  def read([x | xs], _) do
    cond do
      is_integer_str(x) -> {String.to_integer(x), xs}
      is_float_str(x) -> {String.to_float(x), xs}
      true -> {String.to_atom(x), xs}
    end
  end

  # for read_list (read simply)
  def read1(x) do
    cond do
      is_integer_str(x) -> String.to_integer(x)
      is_float_str(x) -> String.to_float(x)
      true -> String.to_atom(x)
    end
  end

  defp read_list([], ls, stream) do
    if stream == :stdin do
      buf = IO.gets("") |> tokenize(stream)
      read_list(buf, ls, stream)
    else
      Elxlog.error("Error: read list", [])
    end
  end

  defp read_list(["]" | xs], ls, _) do
    {ls, xs}
  end

  defp read_list(["[" | xs], ls, stream) do
    {s, rest} = read_list(xs, [], stream)
    read_list(rest, ls ++ [s], stream)
  end

  defp read_list(["" | xs], ls, stream) do
    read_list(xs, ls, stream)
  end

  defp read_list([x, "|" | xs], ls, stream) do
    s = read1(x)
    {s1, rest} = read_list(xs, [], stream)
    {ls ++ [s] ++ hd(s1), rest}
  end

  defp read_list([x, "," | xs], ls, stream) do
    s = read1(x)
    read_list(xs, ls ++ [s], stream)
  end

  defp read_list([x, "]" | xs], ls, _) do
    s = read1(x)
    {ls ++ [s], xs}
  end

  defp read_list(x, _, _) do
    IO.inspect(x)
    Elxlog.error("Error: read_list ", [])
  end

  defp read_tuple([], ls, stream) do
    if stream == :stdin do
      buf = IO.gets("") |> tokenize(stream)
      read_tuple(buf, ls, stream)
    else
      Elxlog.error("Error: read tuple", [])
    end
  end

  defp read_tuple([")" | xs], ls, _) do
    {ls, xs}
  end

  defp read_tuple(["(" | xs], ls, stream) do
    {s, rest} = parse(xs, stream)
    read_tuple(rest, ls ++ [s], stream)
  end

  defp read_tuple(["" | xs], ls, stream) do
    read_tuple(xs, ls, stream)
  end

  defp read_tuple(["," | xs], ls, stream) do
    read_tuple(xs, ls, stream)
  end

  defp read_tuple(x, ls, stream) do
    {s, rest} = read(x, stream)
    read_tuple(rest, ls ++ [s], stream)
  end

  def tokenize(str, stream) do
    str |> String.to_charlist() |> tokenize1([], [], stream)
  end

  def tokenize1([], [], res, _) do
    Enum.reverse(res)
  end

  def tokenize1([], token, res, _) do
    token1 = Enum.reverse(token) |> List.to_string()
    res1 = [token1 | res]
    Enum.reverse(res1)
  end

  # tab
  def tokenize1([9 | ls], [], res, stream) do
    tokenize1(ls, [], res, stream)
  end

  # LF
  def tokenize1([10 | ls], [], res, stream) do
    tokenize1(ls, [], res, stream)
  end

  def tokenize1([10 | ls], token, res, stream) do
    token1 = token |> Enum.reverse() |> List.to_string()
    tokenize1(ls, [], [token1 | res], stream)
  end

  # CR
  def tokenize1([13 | ls], [], res, stream) do
    tokenize1(ls, [], res, stream)
  end

  def tokenize1([13 | ls], token, res, stream) do
    token1 = token |> Enum.reverse() |> List.to_string()
    tokenize1(ls, [], [token1 | res], stream)
  end

  # comment %
  def tokenize1([37 | ls], [], res, stream) do
    ls1 = comment_skip(ls)
    tokenize1(ls1, [], res, stream)
  end

  # space
  def tokenize1([32, 32 | ls], token, res, stream) do
    tokenize1(ls, token, res, stream)
  end

  def tokenize1([32 | ls], [], res, stream) do
    tokenize1(ls, [], res, stream)
  end

  def tokenize1([32 | ls], token, res, stream) do
    token1 = token |> Enum.reverse() |> List.to_string()
    tokenize1(ls, [], [token1 | res], stream)
  end

  def tokenize1([40 | ls], [], res, stream) do
    tokenize1(ls, [], ["(" | res], stream)
  end

  def tokenize1([40 | ls], token, res, stream) do
    token1 = token |> Enum.reverse() |> List.to_string()
    tokenize1(ls, [], ["(", token1 | res], stream)
  end

  def tokenize1([41 | ls], [], res, stream) do
    tokenize1(ls, [], [")" | res], stream)
  end

  def tokenize1([41 | ls], token, res, stream) do
    token1 = token |> Enum.reverse() |> List.to_string()
    tokenize1(ls, [], [")", token1 | res], stream)
  end

  def tokenize1([91 | ls], [], res, stream) do
    tokenize1(ls, [], ["[" | res], stream)
  end

  def tokenize1([91 | ls], token, res, stream) do
    token1 = token |> Enum.reverse() |> List.to_string()
    tokenize1(ls, [], ["[", token1 | res], stream)
  end

  def tokenize1([93 | ls], [], res, stream) do
    tokenize1(ls, [], ["]" | res], stream)
  end

  def tokenize1([93 | ls], token, res, stream) do
    token1 = token |> Enum.reverse() |> List.to_string()
    tokenize1(ls, [], ["]", token1 | res], stream)
  end

  def tokenize1([124 | ls], [], res, stream) do
    tokenize1(ls, [], ["|" | res], stream)
  end

  def tokenize1([124 | ls], token, res, stream) do
    token1 = token |> Enum.reverse() |> List.to_string()
    tokenize1(ls, [], ["|", token1 | res], stream)
  end

  def tokenize1([44 | ls], [], res, stream) do
    tokenize1(ls, [], ["," | res], stream)
  end

  def tokenize1([44 | ls], token, res, stream) do
    token1 = token |> Enum.reverse() |> List.to_string()
    tokenize1(ls, [], [",", token1 | res], stream)
  end

  def tokenize1([46 | ls], [], res, stream) do
    if (ls == [10] || ls == [13]) && stream == :stdin do
      Enum.reverse(["." | res])
    else
      if (hd(ls) == 10 || hd(ls) == 13) && stream == :filein do
        tokenize1(ls, [], ["." | res], stream)
      else
        tokenize1(ls, [46], res, stream)
      end
    end
  end

  def tokenize1([46 | ls], token, res, stream) do
    if (ls == [10] || ls == [13]) && stream == :stdin do
      token1 = token |> Enum.reverse() |> List.to_string()
      Enum.reverse([".", token1 | res])
    else
      if (hd(ls) == 10 || hd(ls) == 13) && stream == :filein do
        token1 = token |> Enum.reverse() |> List.to_string()
        tokenize1(ls, [], [".", token1 | res], stream)
      else
        tokenize1(ls, [46 | token], res, stream)
      end
    end
  end

  def tokenize1([43 | ls], [], res, stream) do
    tokenize1(ls, [], ["+" | res], stream)
  end

  def tokenize1([43 | ls], token, res, stream) do
    token1 = token |> Enum.reverse() |> List.to_string()
    tokenize1(ls, [], ["+", token1 | res], stream)
  end

  def tokenize1([58, 45 | ls], [], res, stream) do
    tokenize1(ls, [], [":-" | res], stream)
  end

  def tokenize1([58, 45 | ls], token, res, stream) do
    token1 = token |> Enum.reverse() |> List.to_string()
    tokenize1(ls, [], [":-", token1 | res], stream)
  end

  def tokenize1([61, 46, 46 | ls], [], res, stream) do
    tokenize1(ls, [], ["=.." | res], stream)
  end

  def tokenize1([61, 46, 46 | ls], token, res, stream) do
    token1 = token |> Enum.reverse() |> List.to_string()
    tokenize1(ls, [], ["=..", token1 | res], stream)
  end

  def tokenize1([61, 61 | ls], [], res, stream) do
    tokenize1(ls, [], ["==" | res], stream)
  end

  def tokenize1([61, 61 | ls], token, res, stream) do
    token1 = token |> Enum.reverse() |> List.to_string()
    tokenize1(ls, [], ["==", token1 | res], stream)
  end

  def tokenize1([33, 61 | ls], [], res, stream) do
    tokenize1(ls, [], ["!=" | res], stream)
  end

  def tokenize1([3, 61 | ls], token, res, stream) do
    token1 = token |> Enum.reverse() |> List.to_string()
    tokenize1(ls, [], ["!=", token1 | res], stream)
  end

  def tokenize1([62, 61 | ls], [], res, stream) do
    tokenize1(ls, [], [">=" | res], stream)
  end

  def tokenize1([62, 61 | ls], token, res, stream) do
    token1 = token |> Enum.reverse() |> List.to_string()
    tokenize1(ls, [], [">=", token1 | res], stream)
  end

  def tokenize1([62 | ls], [], res, stream) do
    tokenize1(ls, [], [">" | res], stream)
  end

  def tokenize1([62 | ls], token, res, stream) do
    token1 = token |> Enum.reverse() |> List.to_string()
    tokenize1(ls, [], [">", token1 | res], stream)
  end

  def tokenize1([60, 61 | ls], [], res, stream) do
    tokenize1(ls, [], ["<=" | res], stream)
  end

  def tokenize1([60, 61 | ls], token, res, stream) do
    token1 = token |> Enum.reverse() |> List.to_string()
    tokenize1(ls, [], ["<=", token1 | res], stream)
  end

  def tokenize1([60 | ls], [], res, stream) do
    tokenize1(ls, [], ["<" | res], stream)
  end

  def tokenize1([60 | ls], token, res, stream) do
    token1 = token |> Enum.reverse() |> List.to_string()
    tokenize1(ls, [], ["<", token1 | res], stream)
  end

  def tokenize1([61 | ls], [], res, stream) do
    tokenize1(ls, [], ["=" | res], stream)
  end

  def tokenize1([61 | ls], token, res, stream) do
    token1 = token |> Enum.reverse() |> List.to_string()
    tokenize1(ls, [], ["=", token1 | res], stream)
  end

  def tokenize1([45 | ls], [], res, stream) do
    tokenize1(ls, [], ["-" | res], stream)
  end

  def tokenize1([45 | ls], token, res, stream) do
    token1 = token |> Enum.reverse() |> List.to_string()
    tokenize1(ls, [], ["-", token1 | res], stream)
  end

  def tokenize1([42 | ls], [], res, stream) do
    tokenize1(ls, [], ["*" | res], stream)
  end

  def tokenize1([42 | ls], token, res, stream) do
    token1 = token |> Enum.reverse() |> List.to_string()
    tokenize1(ls, [], ["*", token1 | res], stream)
  end

  def tokenize1([47 | ls], [], res, stream) do
    tokenize1(ls, [], ["/" | res], stream)
  end

  def tokenize1([47 | ls], token, res, stream) do
    token1 = token |> Enum.reverse() |> List.to_string()
    tokenize1(ls, [], ["/", token1 | res], stream)
  end

  def tokenize1([94 | ls], [], res, stream) do
    tokenize1(ls, [], ["^" | res], stream)
  end

  def tokenize1([94 | ls], token, res, stream) do
    token1 = token |> Enum.reverse() |> List.to_string()
    tokenize1(ls, [], ["^", token1 | res], stream)
  end

  # '....' quote
  def tokenize1([39 | ls], [], res, stream) do
    {atom, rest} = quote_token(ls, [])
    tokenize1(rest, [], [atom | res], stream)
  end

  def tokenize1([39 | ls], token, res, stream) do
    {atom, rest} = quote_token(ls, [])
    token1 = token |> Enum.reverse() |> List.to_string()
    tokenize1(rest, [], [atom, token1 | res], stream)
  end

  def tokenize1([l | ls], token, res, stream) do
    tokenize1(ls, [l | token], res, stream)
  end

  defp comment_skip([]) do
    []
  end

  defp comment_skip([10 | ls]) do
    ls
  end

  defp comment_skip([13 | ls]) do
    ls
  end

  defp comment_skip([_ | ls]) do
    comment_skip(ls)
  end

  defp quote_token([], _) do
    Elxlog.error("Error: illegal quote", [])
  end

  defp quote_token([39 | ls], token) do
    atom = token |> Enum.reverse() |> List.to_string()
    {atom, ls}
  end

  defp quote_token([l | ls], token) do
    quote_token(ls, [l | token])
  end

  defp is_integer_str(x) do
    cond do
      x == "" ->
        false

      # 123
      Enum.all?(x |> String.to_charlist(), fn y -> y >= 48 and y <= 57 end) ->
        true

      # +123
      # +
      String.length(x) >= 2 and
        x |> String.to_charlist() |> hd == 43 and
          Enum.all?(x |> String.to_charlist() |> tl, fn y -> y >= 48 and y <= 57 end) ->
        true

      # -123
      # -
      String.length(x) >= 2 and
        x |> String.to_charlist() |> hd == 45 and
          Enum.all?(x |> String.to_charlist() |> tl, fn y -> y >= 48 and y <= 57 end) ->
        true

      true ->
        false
    end
  end

  defp is_float_str(x) do
    y = String.split(x, ".")
    z = String.split(x, "e")

    cond do
      length(y) == 1 and length(z) == 1 -> false
      length(y) == 2 and is_integer_str(hd(y)) and is_integer_str(hd(tl(y))) -> true
      length(z) == 2 and is_float_str(hd(z)) and is_integer_str(hd(tl(z))) -> true
      true -> false
    end
  end
end
