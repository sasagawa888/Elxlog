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
                  "atom","atomic","integer","float","number","reconsult",
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

  def parse(buf,stream) do
    {s1,buf1} = read(buf,stream)
    {s2,buf2} = read(buf1,stream)
    if s2 == :. do {s1,buf2}
    else if s2 == :":-" do
      {s3,buf3} = parse1(buf2,[],stream)
      {[:clause,s1,s3],buf3}
    else if s2 == :',' do
      {s3,buf3} = parse1(buf2,[s1],stream)
      {s3,buf3}
    else if is_infix_builtin(s2) do
      {s3,buf3,status} = parse2([],[],buf2,stream)
      cond do
        status == :. -> {[:builtin,[s2,s1,s3]],buf3}
        status == :"," -> parse1(buf3,[[:builtin,[s2,s1,s3]]],stream)
        true -> throw "error parse1"
      end
    else
      throw "error parse"
    end
    end
    end
    end
  end

  def parse1(buf,res,stream) do
    {s1,buf1} = read(buf,stream)
    {s2,buf2} = read(buf1,stream)
    if s2 == :. do
      {res++[s1],buf2}
    else if s2 == :")" do
      {res++[s1],buf2}
    else if s2 == :"," do
      parse1(buf2,res++[s1],stream)
    else if is_infix_builtin(s2) do
      {s3,buf3,status} = parse2([],[],buf2,stream)
      if status == :"," do
        parse1(buf3,[[:builtin,[s2,s1,s3]]],stream)
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
  def parse2([],[],buf,stream) do
    #IO.inspect binding()
    {s,buf1} = read(buf,stream)
    cond do
      s == :. -> throw "error 21"
      is_func_atom(s) -> parse2([],[s],buf1,stream)
      true -> parse2([s],[],buf1,stream)
    end
  end
  def parse2([o1],[],buf,stream) do
    #IO.inspect binding()
    {s,buf1} = read(buf,stream)
    cond do
      s == :. -> {o1,buf1,:.}
      s == :"," -> {o1,buf1,:","}
      is_func_atom(s) -> parse2([o1],[s],buf1,stream)
      true -> throw "error 22"
    end
  end
  def parse2([o1],[f1],buf,stream) do
    #IO.inspect binding()
    {s,buf1} = read(buf,stream)
    cond do
      is_func_atom(s) -> throw "error 23"
      true -> parse2([s,o1],[f1],buf1,stream)
    end
  end
  def parse2([o1,o2],[f1],buf,stream) do
    #IO.inspect binding()
    {s,buf1} = read(buf,stream)
    cond do
      s == :. -> {[:formula,[f1,o2,o1]],buf1,:.}
      s == :"," -> {[:formula,[f1,o2,o1]],buf1,:","}
      s == :")" -> {[:formula,[f1,o2,o1]],buf1,:")"}
      is_func_atom(s) && weight(s)>=weight(f1) -> parse2([[f1,o2,o1]],[s],buf1,stream)
      is_func_atom(s) && weight(s)<weight(f1) -> parse2([o1,o2],[s,f1],buf1,stream)
      true -> throw "error 24"
    end
  end
  def parse2([o1,o2],[f1,f2],buf,stream) do
    #IO.inspect binding()
    {s,buf1} = read(buf,stream)
    cond do
      s == :.  -> throw "Error 25"
      is_func_atom(s) -> throw "error 26"
      true -> parse2([[f2,o2,[f1,o1,s]]],[],buf1,stream)
    end
  end

  defp weight(:+) do 100 end
  defp weight(:-) do 100 end
  defp weight(:*) do 50 end
  defp weight(:/) do 50 end

  def read([],stream) do
    if stream == :stdin do
      buf = IO.gets("") |> tokenize
      read(buf,stream)
    else
      []
    end
  end
  def read([""|xs],stream) do
    read(xs,stream)
  end
  def read(["."|xs],_) do
    {:.,xs}
  end
  def read([")"|xs],_) do
    {:")",xs}
  end
  def read(["["|xs],stream) do
    read_list(xs,[],stream)
  end
  def read([x,"("|xs],stream) do
    {tuple,rest} = read_tuple(xs,[],stream)
    cond do
      is_builtin_str(x) -> {[:builtin,[String.to_atom(x)|tuple]],rest}
      is_func_str(x) -> {[String.to_atom(x)|tuple],rest}
      true -> {[:pred,[String.to_atom(x)|tuple]],rest}
    end
  end
  def read([x,"."|_],_) do
    cond do
      is_builtin_str(x) -> {[:builtin,[String.to_atom(x)]],["."]}
      is_atom_str(x) -> {[:pred,[String.to_atom(x)]],["."]}
      is_var_str(x) -> {String.to_atom(x),["."]}
      is_integer_str(x) ->{String.to_integer(x),["."]}
      is_float_str(x) -> {String.to_float(x),["."]}
      true -> {String.to_atom(x),["."]}
    end
  end
  def read([x,","|xs],_) do
    cond do
      is_builtin_str(x) -> {[:builtin,[String.to_atom(x)]],[","|xs]}
      is_atom_str(x) -> {[:pred,[String.to_atom(x)]],[","|xs]}
      is_var_str(x) -> {String.to_atom(x),[","|xs]}
      is_integer_str(x) ->{String.to_integer(x),[","|xs]}
      is_float_str(x) -> {String.to_float(x),[","|xs]}
      true -> {x,[","|xs]}
    end
  end
  def read([x|xs],_) do
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


  defp read_list([],ls,stream) do
    if stream == :stdin do
      buf = IO.gets("") |> tokenize
      read_list(buf,ls,stream)
    else
      throw "Error read list"
    end
  end
  defp read_list(["]"|xs],ls,_) do
    {ls,xs}
  end
  defp read_list(["["|xs],ls,stream) do
    {s,rest} = read_list(xs,[],stream)
    read_list(rest,ls++[s],stream)
  end
  defp read_list([""|xs],ls,stream) do
    read_list(xs,ls,stream)
  end
  defp read_list([x,"|"|xs],ls,stream) do
    s = read1(x)
    {s1,rest} = read_list(xs,[],stream)
    {ls++[s]++hd(s1),rest}
  end
  defp read_list([x,","|xs],ls,stream) do
    s = read1(x)
    read_list(xs,ls++[s],stream)
  end
  defp read_list([x,"]",","|xs],ls,_) do
    s = read1(x)
    {ls++[s],xs}
  end
  defp read_list([x,"]"|xs],ls,_) do
    s = read1(x)
    {ls++[s],xs}
  end

  defp read_tuple([],ls,stream) do
    if stream == :stdin do
      buf = IO.gets("") |> tokenize
      read_tuple(buf,ls,stream)
    else
      throw "Error read tuple"
    end
  end
  defp read_tuple([")"|xs],ls,_) do
    {ls,xs}
  end
  defp read_tuple(["("|xs],ls,stream) do
    {s,rest} = parse(xs,stream)
    read_tuple(rest,ls++[s],stream)
  end
  defp read_tuple([""|xs],ls,stream) do
    read_tuple(xs,ls,stream)
  end
  defp read_tuple([","|xs],ls,stream) do
    read_tuple(xs,ls,stream)
  end
  defp read_tuple(x,ls,stream) do
    {s,rest} = read(x,stream)
    read_tuple(rest,ls++[s],stream)
  end


  def tokenize(str) do
    str |> String.to_charlist |> tokenize1([],[])
  end

  defp tokenize1([],[],res) do
    Enum.reverse(res)
  end
  defp tokenize1([],token,res) do
    token1 = Enum.reverse(token) |> List.to_string
    res1 = [token1|res]
    Enum.reverse(res1)
  end
  # LF
  defp tokenize1([10|ls],[],res) do
    tokenize1(ls,[],res)
  end
  defp tokenize1([10|ls],token,res) do
    token1 = token |> Enum.reverse |> List.to_string
    tokenize1(ls,[],[token1|res])
  end
  # CR
  defp tokenize1([13|ls],[],res) do
    tokenize1(ls,[],res)
  end
  defp tokenize1([13|ls],token,res) do
    token1 = token |> Enum.reverse |> List.to_string
    tokenize1(ls,[],[token1|res])
  end
  # comment %
  defp tokenize1([37|ls],[],res) do
    ls1 = comment_skip(ls)
    tokenize1(ls1,[],res)
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

  defp comment_skip([]) do [] end
  defp comment_skip([10|ls]) do
    ls
  end
  defp comment_skip([13|ls]) do
    ls
  end
  defp comment_skip([_|ls]) do
    comment_skip(ls)
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
