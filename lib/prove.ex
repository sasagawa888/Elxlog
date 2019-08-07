#----------------prove-----------------------------------
defmodule Prove do
  def prove([:pred,x],y,env,def,n) do
    [name|_] = x
    def1 = def[name]
    prove_pred([:pred,x],def1,y,env,def,n)
  end
  def prove([:builtin,x],y,env,def,n) do
    prove_builtin(x,y,env,def,n)
  end

  def prove_all([],env,def,_) do {true,env,def} end
  def prove_all([x|xs],env,def,n) do
    prove(x,xs,env,def,n)
  end

  def prove_pred(_,nil,_,env,def,_) do {false,env,def} end
  def prove_pred(_,[],_,env,def,_) do {false,env,def} end
  def prove_pred(x,[d|ds],y,env,def,n) do
    d1 = alpha_conv(d,n)
    #IO.inspect(d1)
    #IO.inspect(env)
    #IO.inspect(y)
    #IO.gets("??")
    if Elxlog.is_pred(d1) do
      env1 = unify(x,d1,env)
      if env1 != false do
        {res,env2,def} = prove_all(y,env1,def,n+1)
        if res == true do
          {res,env2,def}
        else
          prove_pred(x,ds,y,env,def,n)
        end
      else
        prove_pred(x,ds,y,env,def,n)
      end
    else if Elxlog.is_clause(d1) do
      env1 = unify(x,head(d1),env)
      if env1 != false do
        {res,env2,def} = prove_all(body(d1)++y,env1,def,n+1)
        if res == true do
          {res,env2,def}
        else
          prove_pred(x,ds,y,env,def,n)
        end
      else
        prove_pred(x,ds,y,env,def,n)
      end
    end
    end
  end


  def prove_builtin([:halt],_,_,_,_) do
    throw "goodbye"
  end
  def prove_builtin([:atom,x],y,env,def,n) do
    x1 = deref(x,env)
    if is_atom(x1) && !Elxlog.is_var(x1) do
      prove_all(y,env,def,n+1)
    else
      {false,env,def}
    end
  end
  def prove_builtin([:atomic,x],y,env,def,n) do
    x1 = deref(x,env)
    if (is_atom(x1) && !Elxlog.is_var(x1)) || is_number(x1) do
      prove_all(y,env,def,n+1)
    else
      {false,env,def}
    end
  end
  def prove_builtin([:integer,x],y,env,def,n) do
    x1 = deref(x,env)
    if is_integer(x1) do
      prove_all(y,env,def,n+1)
    else
      {false,env,def}
    end
  end
  def prove_builtin([:float,x],y,env,def,n) do
    x1 = deref(x,env)
    if is_float(x1) do
      prove_all(y,env,def,n+1)
    else
      {false,env,def}
    end
  end
  def prove_builtin([:number,x],y,env,def,n) do
    x1 = deref(x,env)
    if is_number(x1) do
      prove_all(y,env,def,n+1)
    else
      {false,env,def}
    end
  end
  def prove_builtin([:var,x],y,env,def,n) do
    x1 = deref(x,env)
    if Elxlog.is_var(x1) do
      prove_all(y,env,def,n+1)
    else
      {false,env,def}
    end
  end
  def prove_builtin([:nonvar,x],y,env,def,n) do
    x1 = deref(x,env)
    if !Elxlog.is_var(x1) do
      prove_all(y,env,def,n+1)
    else
      {false,env,def}
    end
  end
  def prove_builtin([:write,x],y,env,def,n) do
    x1 = deref(x,env)
    Print.print1(x1)
    prove_all(y,env,def,n+1)
  end
  def prove_builtin([:nl],y,env,def,n) do
    IO.puts("")
    prove_all(y,env,def,n+1)
  end
  def prove_builtin([:reconsult,x],y,env,def,n) do
    {:ok,string} = File.read(Atom.to_string(x))
    buf = string |> Read.tokenize()
    def1 = reconsult(buf,def)
    prove_all(y,env,def1,n+1)
  end
  def prove_builtin([:assert,x],y,env,def,n) do
    if Elxlog.is_pred(x) do
      [_,[name|_]] = x
      def1 = find_def(def,name)
      def2 = Keyword.put(def,name,def1++[x])
      prove_all(y,env,def2,n+1)
    else
      #clause
      [_,[_,[name|_]],_] = x
      def1 = find_def(def,name)
      def2 = Keyword.put(def,name,def1++[x])
      prove_all(y,env,def2,n+1)
    end
  end
  def prove_builtin([:is,a,b],y,env,def,n) do
    b1 = eval(b,env)
    env1 = unify(a,b1,env)
    prove_all(y,env1,def,n+1)
  end
  def prove_builtin([:listing],y,env,def,n) do
    listing(def,[])
    prove_all(y,env,def,n+1)
  end
  def prove_builtin([:debug],y,env,def,n) do
    debug(def,[])
    prove_all(y,env,def,n+1)
  end
  def prove_builtin([:=,a,b],y,env,def,n) do
    env1 = unify(a,b,env)
    if env1 == false do
      {false,env,def}
    else
      prove_all(y,env1,def,n+1)
    end
  end
  def prove_builtin([:>,a,b],y,env,def,n) do
    a1 = eval(a,env)
    b1 = eval(b,env)
    if a1 > b1 do
      prove_all(y,env,def,n+1)
    else
      {false,env,def}
    end
  end
  def prove_builtin([:"=>",a,b],y,env,def,n) do
    a1 = eval(a,env)
    b1 = eval(b,env)
    if a1 >= b1 do
      prove_all(y,env,def,n+1)
    else
      {false,env,def}
    end
  end
  def prove_builtin([:<,a,b],y,env,def,n) do
    a1 = eval(a,env)
    b1 = eval(b,env)
    if a1 < b1 do
      prove_all(y,env,def,n+1)
    else
      {false,env,def}
    end
  end
  def prove_builtin([:"=<",a,b],y,env,def,n) do
    a1 = eval(a,env)
    b1 = eval(b,env)
    if a1 <= b1 do
      prove_all(y,env,def,n+1)
    else
      {false,env,def}
    end
  end
  def prove_builtin([:ask],y,env,def,n) do
    prove_all(y,env,def,n+1)
  end
  def prove_builtin([:ask|vars],y,env,def,n) do
    ask(vars,env)
    ans = IO.gets("")
    cond do
      ans == ".\n" -> prove_all(y,env,def,n+1)
      ans == ";\n" -> {false,env,def}
      true -> prove_all(y,env,def,n+1)
    end
  end
  def prove_builtin(x,_,_,_,_) do
    IO.inspect(x)
    throw "error builtin"
  end

  def eval(x,_) when is_number(x) do x end
  def eval(x,env) when is_atom(x) do
    x1 = deref(x,env)
    if x == x1 do
      throw "Error eval ununified #{x}"
    else
      x1
    end
  end
  def eval([:formula,x],env) do
    eval(x,env)
  end
  def eval([:func,x],env) do
    {x1,_} = Code.eval_string(func_to_str(x),env,__ENV__)
    eval(x1,env)
  end
  def eval([:+,x,y],env) do
    eval(x,env) + eval(y,env)
  end
  def eval([:-,x,y],env) do
    eval(x,env) - eval(y,env)
  end
  def eval([:*,x,y],env) do
    eval(x,env) * eval(y,env)
  end
  def eval([:/,x,y],env) do
    eval(x,env) / eval(y,env)
  end
  def eval([:^,x,y],env) do
    :math.pow(eval(x,env),eval(y,env))
  end
  def eval(x,env) do
    deref(x,env)
  end

  def func_to_str([name|args]) do
    ["Elxfunc."]++[Atom.to_string(name)]++[list_to_str(args)] |> Enum.join()
  end

  def list_to_str(x) do
    ["("]++list_to_str1(x)++[")"]
  end

  def list_to_str1([]) do [""] end
  def list_to_str1([x]) do
    cond do
      is_integer(x) -> [Integer.to_string(x)]
      is_float(x) -> [Float.to_string(x)]
      is_atom(x) -> [Atom.to_string(x)]
    end
  end
  def list_to_str1([x|xs]) do
    cond do
      is_integer(x) -> [Integer.to_string(x)]++[","]++list_to_str1(xs)
      is_float(x) -> [Float.to_string(x)]++[","]++list_to_str1(xs)
      is_atom(x) -> [Atom.to_string(x)]++[","]++list_to_str1(xs)
    end
  end

  def ask([],_) do true end
  def ask([x],env) do
    IO.write(x)
    IO.write(" = ")
    Print.print1(deref(x,env))
  end
  def ask([x|xs],env) do
    IO.write(x)
    IO.write(" = ")
    Print.print(deref(x,env))
    ask(xs,env)
  end

  def reconsult([],def) do def end
  def reconsult(buf,def) do
    {s,buf1} = Read.parse(buf,:stdin)
    {_,_,def1} = Prove.prove(s,[],[],def,1)
    reconsult(buf1,def1)
  end

  def listing([],_) do true end
  def listing([{key,body}|rest],check) do
    if Enum.member?(check,key) do
      listing(rest,check)
    else
      listing1(body)
      listing(rest,[key|check])
    end
  end

  def listing1([]) do true end
  def listing1([x|xs]) do
    Print.print(x)
    listing1(xs)
  end

  def debug([],_) do true end
  def debug([{key,body}|rest],check) do
    if Enum.member?(check,key) do
      debug(rest,check)
    else
      debug1(body)
      debug(rest,[key|check])
    end
  end

  def debug1([]) do true end
  def debug1([x|xs]) do
    Print.print_debug(x)
    debug1(xs)
  end



  def find_def(ls,name) do
    def = ls[name]
    if def == nil do
      []
    else
      def
    end
  end


  #dereference
  def deref(x,_) when is_number(x) do x end
  def deref(x,env) when is_atom(x) do
    x1 = deref1(x,env,env)
    if x1 == false do
      x
    else
      deref(x1,env)
    end
  end
  def deref({x,n},env) when is_atom(x) do
    x1 = deref1({x,n},env,env)
    if x1 == false do
      {x,n}
    else
      deref(x1,env)
    end
  end
  def deref([],_) do [] end
  def deref([x|xs],env) do
    x1 = deref1(x,env,env)
    if x1 == false do
      [x|deref(xs,env)]
    else
      [x1|deref(xs,env)]
    end
  end

  def deref1(_,[],_) do false end
  def deref1(x,[[x,v]|_],env) do
    if !Elxlog.is_var(v) do
      v
    else
      deref1(v,env,env)
    end
  end
  def deref1(x,[_|es],env) do
    deref1(x,es,env)
  end

  #clause head
  def head([:clause,h,_]) do h end
  #clause body
  def body([:clause,_,b]) do b end

  #alpha convert :X -> {:X,n}
  def alpha_conv([],_) do [] end
  def alpha_conv(x,_) when is_number(x) do x end
  def alpha_conv(x,n) when is_atom(x) do
    if Elxlog.is_atomvar(x) do
      {x,n}
    else
      x
    end
  end
  def alpha_conv([x|y],n) when is_atom(x) do
    if Elxlog.is_atomvar(x) do
      [{x,n}|alpha_conv(y,n)]
    else
      [x|alpha_conv(y,n)]
    end
  end
  def alpha_conv([x|y],n) when is_number(x) do
    [x|alpha_conv(y,n)]
  end
  def alpha_conv([x|y],n) when is_list(x) do
    [alpha_conv(x,n)|alpha_conv(y,n)]
  end

  def unify([],[],env) do env end
    #IO.inspect binding()
  def unify([x|xs],[y|ys],env) do
    #IO.inspect binding()
    x1 = deref(x,env)
    y1 = deref(y,env)
    cond do
      Elxlog.is_anonymous(x1) || Elxlog.is_anonymous(y1) -> unify(xs,ys,env)
      Elxlog.is_var(x1) && !Elxlog.is_var(y1) -> unify(xs,ys,[[x1,y1]|env])
      !Elxlog.is_var(x1) && Elxlog.is_var(y1) -> unify(xs,ys,[[y1,x1]|env])
      Elxlog.is_var(x1) && Elxlog.is_var(y1) -> unify(xs,ys,[[x1,y1]|env])
      x1 == [] && y1 != [] -> false
      x1 != [] && y1 == [] -> false
      is_list(x1) && is_list(y1) -> unify1(x1,y1,xs,ys,env)
      x1 == y1 -> unify(xs,ys,env)
      true -> false
    end
  end
  # atom or number
  def unify(x,y,env) do
    unify([x],[y],env)
  end

  def unify1(x,y,xs,ys,env) do
    env1 = unify(x,y,env)
    if env1 != false do
      unify(xs,ys,env1)
    else
      false
    end
  end

end
