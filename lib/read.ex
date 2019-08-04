#---------------read----------------------------------
defmodule Read do
  # lowercase or number char or underbar
  def is_atom_str(x) do
    y = String.to_charlist(x)
    if hd(y) >= 97 && hd(y) <= 122 &&
       Enum.all?(y,fn(z) -> (z >= 97 && z <=122) || (z >= 48  && z <= 57) || z == 95 end) do
         true
    else
        false
    end
  end

  def is_builtin_str(x) do
    Enum.member?(["assert","halt","write","nl","is","listing","ask","debug",
                  "atom","atomic","integer","float","number",
                  ":-",">","<","=>","=<"],x)
  end

  def is_func_str(x) do
    Enum.member?(["+","-","*","/","^"],x)
  end

  def is_var_str(x) do
    x1 = String.at(x,0)
    Enum.member?(["_","A","B","C","D","E","F","G","H","I","j","K","L","M","N",
                  "O","P","Q","R","S","T","U","V","W","X","Y","Z"],x1)
  end

  def is_func_atom(x) do
    Enum.member?([:+,:-,:*,:/,:^],x)
  end

  def is_infix_builtin(x) do
    Enum.member?([:is,:=,:"=..",:==,:"=>",:"=<",:>,:<,:^],x)
  end

  def parse(buf) do
    {s1,buf1} = read(buf)
    {s2,buf2} = read(buf1)
    if s2 == :. do {s1,[]}
    else if s2 == :":-" do
      {s3,buf3} = parse1(buf2,[])
      {[:clause,s1,s3],buf3}
    else if s2 == :',' do
      {s3,buf3} = parse1(buf2,[s1])
      {s3,buf3}
    else if is_infix_builtin(s2) do
      {s3,buf3,status} = parse2([],[],buf2)
      cond do
        status == :. -> {[:builtin,[s2,s1,s3]],buf3}
        status == :"," -> parse1(buf3,[[:builtin,[s2,s1,s3]]])
        true -> throw "error parse1"
      end
    else
      throw "error parse"
    end
    end
    end
    end
  end

  def parse1(buf,res) do
    {s1,buf1} = read(buf)
    {s2,buf2} = read(buf1)
    if s2 == :. do
      {res++[s1],buf2}
    else if s2 == :")" do
      {res++[s1],buf2}
    else if s2 == :"," do
      parse1(buf2,res++[s1])
    else if is_infix_builtin(s2) do
      {s3,buf3,status} = parse2([],[],buf2)
      if status == :"," do
        parse1(buf3,[[:builtin,[s2,s1,s3]]])
      else if status == :. do
        {res++[[:builtin,[s2,s1,s3]]],buf3}
      else if status == :")" do
        {res++[[:builtin,[s2,s1,s3]]],buf3}
      end
      end
      end
    else
      throw "error parse1"
    end
    end
    end
    end
  end

  # parse formula
  def parse2([],[],buf) do
    #IO.inspect binding()
    {s,buf1} = read(buf)
    cond do
      s == :. -> throw "error 21"
      is_func_atom(s) -> parse2([],[s],buf1)
      true -> parse2([s],[],buf1)
    end
  end
  def parse2([o1],[],buf) do
    #IO.inspect binding()
    {s,buf1} = read(buf)
    cond do
      s == :. -> {o1,buf1,:.}
      s == :"," -> {o1,buf1,:","}
      is_func_atom(s) -> parse2([o1],[s],buf1)
      true -> throw "error 22"
    end
  end
  def parse2([o1],[f1],buf) do
    #IO.inspect binding()
    {s,buf1} = read(buf)
    cond do
      is_func_atom(s) -> throw "error 23"
      true -> parse2([s,o1],[f1],buf1)
    end
  end
  def parse2([o1,o2],[f1],buf) do
    #IO.inspect binding()
    {s,buf1} = read(buf)
    cond do
      s == :. -> {[:formula,[f1,o2,o1]],buf1,:.}
      s == :"," -> {[:formula,[f1,o2,o1]],buf1,:","}
      s == :")" -> {[:formula,[f1,o2,o1]],buf1,:")"}
      is_func_atom(s) && weight(s)>=weight(f1) -> parse2([[f1,o2,o1]],[s],buf1)
      is_func_atom(s) && weight(s)<weight(f1) -> parse2([o1,o2],[s,f1],buf1)
      true -> throw "error 24"
    end
  end
  def parse2([o1,o2],[f1,f2],buf) do
    #IO.inspect binding()
    {s,buf1} = read(buf)
    cond do
      s == :.  -> throw "Error 25"
      is_func_atom(s) -> throw "error 26"
      true -> parse2([[f2,o2,[f1,o1,s]]],[],buf1)
    end
  end

  defp weight(:+) do 100 end
  defp weight(:-) do 100 end
  defp weight(:*) do 50 end
  defp weight(:/) do 50 end

  def read([]) do
    buf = IO.gets("") |> comment_line |> drop_eol |> tokenize
    read(buf)
  end
  def read([""|xs]) do
    read(xs)
  end
  def read(["."|xs]) do
    {:.,xs}
  end
  def read([")"|xs]) do
    {:")",xs}
  end
  def read(["["|xs]) do
    read_list(xs,[])
  end
  def read([x,"("|xs]) do
    {tuple,rest} = read_tuple(xs,[])
    cond do
      is_builtin_str(x) -> {[:builtin,[String.to_atom(x)|tuple]],rest}
      is_func_str(x) -> {[String.to_atom(x)|tuple],rest}
      true -> {[:pred,[String.to_atom(x)|tuple]],rest}
    end
  end
  def read([x,"."|_]) do
    cond do
      is_builtin_str(x) -> {[:builtin,[String.to_atom(x)]],["."]}
      is_atom_str(x) -> {[:pred,[String.to_atom(x)]],["."]}
      is_var_str(x) -> {String.to_atom(x),["."]}
      is_integer_str(x) ->{String.to_integer(x),["."]}
      is_float_str(x) -> {String.to_float(x),["."]}
      true -> {String.to_atom(x),["."]}
    end
  end
  def read([x,","|xs]) do
    cond do
      is_builtin_str(x) -> {[:builtin,[String.to_atom(x)]],[","|xs]}
      is_atom_str(x) -> {[:pred,[String.to_atom(x)]],[","|xs]}
      is_var_str(x) -> {String.to_atom(x),[","|xs]}
      is_integer_str(x) ->{String.to_integer(x),[","|xs]}
      is_float_str(x) -> {String.to_float(x),[","|xs]}
      true -> {x,[","|xs]}
    end
  end
  def read([x|xs]) do
    cond do
      is_integer_str(x) -> {String.to_integer(x),xs}
      is_float_str(x) -> {String.to_float(x),xs}
      true -> {String.to_atom(x),xs}
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


  defp read_list([],ls) do
    buf = IO.gets("") |> comment_line |> drop_eol |> tokenize
    read_list(buf,ls)
  end
  defp read_list(["]"|xs],ls) do
    {ls,xs}
  end
  defp read_list(["["|xs],ls) do
    {s,rest} = read_list(xs,[])
    read_list(rest,ls++[s])
  end
  defp read_list([""|xs],ls) do
    read_list(xs,ls)
  end
  defp read_list([x,"|"|xs],ls) do
    s = read1(x)
    {s1,rest} = read_list(xs,[])
    {ls++[s]++hd(s1),rest}
  end
  defp read_list([x,","|xs],ls) do
    s = read1(x)
    read_list(xs,ls++[s])
  end
  defp read_list([x,"]",","|xs],ls) do
    s = read1(x)
    {ls++[s],xs}
  end
  defp read_list([x,"]"|xs],ls) do
    s = read1(x)
    {ls++[s],xs}
  end

  defp read_tuple([],ls) do
    buf = IO.gets("") |> comment_line |> drop_eol |> tokenize
    read_tuple(buf,ls)
  end
  defp read_tuple([")"|xs],ls) do
    {ls,xs}
  end
  defp read_tuple(["("|xs],ls) do
    {s,rest} = parse(xs)
    read_tuple(rest,ls++[s])
  end
  defp read_tuple([""|xs],ls) do
    read_tuple(xs,ls)
  end
  defp read_tuple([","|xs],ls) do
    read_tuple(xs,ls)
  end
  defp read_tuple(x,ls) do
    {s,rest} = read(x)
    read_tuple(rest,ls++[s])
  end


  defp tokenize(str) do
    str |> String.to_charlist |> tokenize1([],[])
  end

  defp tokenize1([],token,res) do
    token1 = Enum.reverse(token) |> List.to_string
    res1 = [token1|res]
    Enum.reverse(res1)
  end
  #space
  defp tokenize1([32,32|ls],token,res) do
    tokenize1(ls,token,res)
  end
  defp tokenize1([32|ls],[],res) do
    tokenize1(ls,[],res)
  end
  defp tokenize1([32|ls],token,res) do
    token1 = token |> Enum.reverse |> List.to_string
    tokenize1(ls,[],[token1|res])
  end
  defp tokenize1([40|ls],[],res) do
    tokenize1(ls,[],["("|res])
  end
  defp tokenize1([40|ls],token,res) do
    token1 = token |> Enum.reverse |> List.to_string
    tokenize1(ls,[],["(",token1|res])
  end
  defp tokenize1([41|ls],[],res) do
    tokenize1(ls,[],[")"|res])
  end
  defp tokenize1([41|ls],token,res) do
    token1 = token |> Enum.reverse |> List.to_string
    tokenize1(ls,[],[")",token1|res])
  end
  defp tokenize1([91|ls],[],res) do
    tokenize1(ls,[],["["|res])
  end
  defp tokenize1([91|ls],token,res) do
    token1 = token |> Enum.reverse |> List.to_string
    tokenize1(ls,[],["[",token1|res])
  end
  defp tokenize1([93|ls],[],res) do
    tokenize1(ls,[],["]"|res])
  end
  defp tokenize1([93|ls],token,res) do
    token1 = token |> Enum.reverse |> List.to_string
    tokenize1(ls,[],["]",token1|res])
  end
  defp tokenize1([124|ls],[],res) do
    tokenize1(ls,[],["|"|res])
  end
  defp tokenize1([124|ls],token,res) do
    token1 = token |> Enum.reverse |> List.to_string
    tokenize1(ls,[],["|",token1|res])
  end
  defp tokenize1([44|ls],[],res) do
    tokenize1(ls,[],[","|res])
  end
  defp tokenize1([44|ls],token,res) do
    token1 = token |> Enum.reverse |> List.to_string
    tokenize1(ls,[],[",",token1|res])
  end
  defp tokenize1([46|ls],[],res) do
    tokenize1(ls,[],["."|res])
  end
  defp tokenize1([46|ls],token,res) do
    token1 = token |> Enum.reverse |> List.to_string
    tokenize1(ls,[],[".",token1|res])
  end
  defp tokenize1([43|ls],[],res) do
    tokenize1(ls,[],["+"|res])
  end
  defp tokenize1([43|ls],token,res) do
    token1 = token |> Enum.reverse |> List.to_string
    tokenize1(ls,[],["+",token1|res])
  end
  defp tokenize1([58,45|ls],[],res) do
    tokenize1(ls,[],[":-"|res])
  end
  defp tokenize1([58,45|ls],token,res) do
    token1 = token |> Enum.reverse |> List.to_string
    tokenize1(ls,[],[":-",token1|res])
  end
  defp tokenize1([45|ls],[],res) do
    tokenize1(ls,[],["-"|res])
  end
  defp tokenize1([45|ls],token,res) do
    token1 = token |> Enum.reverse |> List.to_string
    tokenize1(ls,[],["-",token1|res])
  end
  defp tokenize1([42|ls],[],res) do
    tokenize1(ls,[],["*"|res])
  end
  defp tokenize1([42|ls],token,res) do
    token1 = token |> Enum.reverse |> List.to_string
    tokenize1(ls,[],["*",token1|res])
  end
  defp tokenize1([47|ls],[],res) do
    tokenize1(ls,[],["/"|res])
  end
  defp tokenize1([47|ls],token,res) do
    token1 = token |> Enum.reverse |> List.to_string
    tokenize1(ls,[],["/",token1|res])
  end
  defp tokenize1([94|ls],token,res) do
    token1 = token |> Enum.reverse |> List.to_string
    tokenize1(ls,[],["^",token1|res])
  end
  # '....' quote
  defp tokenize1([39|ls],[],res) do
    {atom,rest} = quote_token(ls,[])
    tokenize1(rest,[],[atom|res])
  end
  defp tokenize1([39|ls],token,res) do
    {atom,rest} = quote_token(ls,[])
    token1 = token |> Enum.reverse |> List.to_string
    tokenize1(rest,[],[atom,token1|res])
  end
  defp tokenize1([l|ls],token,res) do
    tokenize1(ls,[l|token],res)
  end

  defp comment_line(x) do
    if String.slice(x,0,1) == ";" do
      IO.gets("? ")
    else
      x
    end
  end

  defp drop_eol(x) do
    String.split(x,"\n") |> hd
  end

  defp quote_token([],_) do
    throw "Error illegal quote"
  end
  defp quote_token([39|ls],token) do
    atom = token |> Enum.reverse() |> List.to_string()
    {atom,ls}
  end
  defp quote_token([l|ls],token) do
    quote_token(ls,[l|token])
  end

  defp is_integer_str(x) do
    cond do
      x == "" -> false
      # 123
      Enum.all?(x |> String.to_charlist, fn(y) -> y >= 48 and y <= 57 end) -> true
      # +123
      String.length(x) >= 2 and
      x |> String.to_charlist |> hd == 43 and # +
      Enum.all?(x |> String.to_charlist |> tl, fn(y) -> y >= 48 and y <= 57 end) -> true
      # -123
      String.length(x) >= 2 and
      x |> String.to_charlist |> hd == 45 and # -
      Enum.all?(x |> String.to_charlist |> tl, fn(y) -> y >= 48 and y <= 57 end) -> true
      true -> false
    end
  end

  defp is_float_str(x) do
    y = String.split(x,".")
    z = String.split(x,"e")
    cond do
      length(y) == 1 and length(z) == 1 -> false
      length(y) == 2 and is_integer_str(hd(y)) and is_integer_str(hd(tl(y))) -> true
      length(z) == 2 and is_float_str(hd(z)) and is_integer_str(hd(tl(z))) -> true
      true -> false
    end
  end

end
