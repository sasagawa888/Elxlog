defmodule ElxlogTest do
  use ExUnit.Case
  doctest Elxlog
  import ExUnit.CaptureIO

  test "deref" do
    env = [
      [{:A, 5}, 1],
      [{:A1, 5}, 1],
      [{:N1, 5}, 0],
      [{:A1, 3}, {:A, 5}],
      [{:N, 5}, 1],
      [{:N1, 3}, 1],
      [{:A1, 1}, {:A, 3}],
      [{:N, 3}, 2],
      [{:N1, 1}, 2],
      [:X, {:A, 1}],
      [{:N, 1}, 3]
    ]

    assert Prove.deref({:A1, 3}, env) == 1
    assert Prove.deref([:+, {:A1, 3}, 3], env) == [:+, 1, 3]
    assert Prove.deref(:X, env) == :X
    assert Prove.deref({:B, 2}, env) == {:B, 2}
    assert Prove.eval([:+, {:A1, 3}, 3], env) == 4
    assert Prove.eval([:-, {:A1, 3}, 3], env) == -2
  end

  test "alpha_conv" do
    clause = [
      :clause,
      [:pred, [:fact, :N, :A]],
      [
        [:builtin, [:is, :N1, [:formula, [:-, :N, 1]]]],
        [:pred, [:fact, :N1, :A1]],
        [:builtin, [:is, :A, [:formula, [:*, :N, :A1]]]]
      ]
    ]

    assert Prove.alpha_conv(clause, 1) == [
             :clause,
             [:pred, [:fact, {:N, 1}, {:A, 1}]],
             [
               [:builtin, [:is, {:N1, 1}, [:formula, [:-, {:N, 1}, 1]]]],
               [:pred, [:fact, {:N1, 1}, {:A1, 1}]],
               [:builtin, [:is, {:A, 1}, [:formula, [:*, {:N, 1}, {:A1, 1}]]]]
             ]
           ]

    clause1 = [
      :clause,
      [:pred, [:append, [:X | :Ls], :Ys, [:X | :Zs]]],
      [[:pred, [:append, :Ls, :Ys, :Zs]]]
    ]

    assert Prove.alpha_conv(clause1, 2) == [
             :clause,
             [
               :pred,
               [
                 :append,
                 [{:X, 2} | {:Ls, 2}],
                 {:Ys, 2},
                 [
                   {:X, 2}
                   | {:Zs, 2}
                 ]
               ]
             ],
             [[:pred, [:append, {:Ls, 2}, {:Ys, 2}, {:Zs, 2}]]]
           ]
  end

  test "variable" do
    assert Elxlog.is_atomvar(:X) == true
    assert Elxlog.is_atomvar(:x) == false
    assert Elxlog.is_variant({:X, 1}) == true
    assert Elxlog.is_variant({:x, 1}) == false
    assert Elxlog.is_var({:X, 1}) == true
    assert Elxlog.is_var(:X) == true
  end

  test "find_var" do
    clause = [
      :clause,
      [:pred, [:fact, :N, :A]],
      [
        [:builtin, [:is, :N1, [:formula, [:-, :N, 1]]]],
        [:pred, [:fact, :N1, :A1]],
        [:builtin, [:is, :A, [:formula, [:*, :N, :A1]]]]
      ]
    ]

    assert Elxlog.find_var(clause) == [:N, :A, :N1, :A1]
    pred = [:pred, [:append, :X, :Y, [1, 2, 3]]]
    assert Elxlog.find_var(pred) == [:X, :Y]
  end

  test "unify" do
    assert Prove.unify([], [], []) == []
    assert Prove.unify([1], [], []) == false
    assert Prove.unify([], [1], []) == false
    assert Prove.unify([1], [1], []) == []
    assert Prove.unify([:pred, [:foo, 1, 2]], [:pred, [:foo, :X, :Y]], []) == [[:Y, 2], [:X, 1]]
    assert Prove.unify([:pred, [:foo, 1, 2]], [:pred, [:foo, :X, 3]], []) == false

    assert Prove.unify([:pred, [:foo, 1, 2]], [:pred, [:foo, {:X, 1}, {:Y, 1}]], []) == [
             [{:Y, 1}, 2],
             [{:X, 1}, 1]
           ]
  end

  test "total" do
    assert capture_io(fn -> Elxlog.bar("append([1,2,3],[4,5],[1,2,3,4,5]).\n") end) == "true\n"
    assert capture_io(fn -> Elxlog.bar("append([1,2,3],[4,5],[1,2,3,4,7]).\n") end) == "false\n"
    assert capture_io(fn -> Elxlog.bar("append([1,2,3],[4,5],X).\n") end) == "true\n"
    assert capture_io(fn -> Elxlog.bar("append([],[],[]).\n") end) == "true\n"
    assert capture_io(fn -> Elxlog.bar("append([1,2,3],[4,5],[1,2,3,4,5]).\n") end) == "true\n"
    assert capture_io(fn -> Elxlog.bar("atom([1,2,3]).\n") end) == "false\n"
    assert capture_io(fn -> Elxlog.bar("atom(a).\n") end) == "true\n"
    assert capture_io(fn -> Elxlog.bar("atom(1).\n") end) == "false\n"
    assert capture_io(fn -> Elxlog.bar("atom(1.1).\n") end) == "false\n"
    assert capture_io(fn -> Elxlog.bar("atom(X).\n") end) == "false\n"
    assert capture_io(fn -> Elxlog.bar("atomic([1,2,3]).\n") end) == "false\n"
    assert capture_io(fn -> Elxlog.bar("atomic(a).\n") end) == "true\n"
    assert capture_io(fn -> Elxlog.bar("atomic(1).\n") end) == "true\n"
    assert capture_io(fn -> Elxlog.bar("atomic(1.1).\n") end) == "true\n"
    assert capture_io(fn -> Elxlog.bar("atomic(X).\n") end) == "false\n"
    assert capture_io(fn -> Elxlog.bar("integer(1).\n") end) == "true\n"
    assert capture_io(fn -> Elxlog.bar("integer(1.1).\n") end) == "false\n"
    assert capture_io(fn -> Elxlog.bar("integer([]).\n") end) == "false\n"
    assert capture_io(fn -> Elxlog.bar("integer(X).\n") end) == "false\n"
    assert capture_io(fn -> Elxlog.bar("float(X).\n") end) == "false\n"
    assert capture_io(fn -> Elxlog.bar("float(1).\n") end) == "false\n"
    assert capture_io(fn -> Elxlog.bar("float([]).\n") end) == "false\n"
    assert capture_io(fn -> Elxlog.bar("float(1.2).\n") end) == "true\n"
    assert capture_io(fn -> Elxlog.bar("float(1.0e3).\n") end) == "true\n"
    assert capture_io(fn -> Elxlog.bar("X is 1+2.\n") end) == "true\n"
    assert capture_io(fn -> Elxlog.bar("3 is 1+2.\n") end) == "true\n"
    assert capture_io(fn -> Elxlog.bar("1 is 3-2.\n") end) == "true\n"
    assert capture_io(fn -> Elxlog.bar("1 is 3+2.\n") end) == "false\n"
    assert capture_io(fn -> Elxlog.bar("1.1 is 3.1-2.\n") end) == "true\n"
    assert capture_io(fn -> Elxlog.bar("30 is 3*(1+2+(3+4)).\n") end) == "true\n"
    assert capture_io(fn -> Elxlog.bar("27 is 3*(4+5).\n") end) == "true\n"
    assert capture_io(fn -> Elxlog.bar("0.3 is 3/(1+2+(3+4)).\n") end) == "true\n"
    assert capture_io(fn -> Elxlog.bar("5 = 3+2.\n") end) == "false\n"
    assert capture_io(fn -> Elxlog.bar("5 = 5.\n") end) == "true\n"
    assert capture_io(fn -> Elxlog.bar("a = a.\n") end) == "true\n"
    assert capture_io(fn -> Elxlog.bar("X = 3.\n") end) == "true\n"
    assert capture_io(fn -> Elxlog.bar("X = 3+2.\n") end) == "true\n"
    assert capture_io(fn -> Elxlog.bar("5 = X.\n") end) == "true\n"
    assert capture_io(fn -> Elxlog.bar("X = Y.\n") end) == "true\n"
    assert capture_io(fn -> Elxlog.bar("length([1,2,3],X).\n") end) == "true\n"
    assert capture_io(fn -> Elxlog.bar("length([1,2,3],3).\n") end) == "true\n"
    assert capture_io(fn -> Elxlog.bar("length([1,2,3],4).\n") end) == "false\n"
    assert capture_io(fn -> Elxlog.bar("member(1,[1,2,3]).\n") end) == "true\n"
    assert capture_io(fn -> Elxlog.bar("member(a,[1,2,3]).\n") end) == "false\n"
    assert capture_io(fn -> Elxlog.bar("member([],[1,2,3]).\n") end) == "false\n"
    assert capture_io(fn -> Elxlog.bar("member(A,[1,2,3]).\n") end) == "true\n"
    assert capture_io(fn -> Elxlog.bar("member(a).\n") end) == "false\n"
    assert capture_io(fn -> Elxlog.bar("name(asdf,[97,115,100,102]).\n") end) == "true\n"
    assert capture_io(fn -> Elxlog.bar("name(X,[97,115,100,102]).\n") end) == "true\n"
    assert capture_io(fn -> Elxlog.bar("name(asdf,X).\n") end) == "true\n"
    assert capture_io(fn -> Elxlog.bar("name(X,X).\n") end) == "false\n"
    assert capture_io(fn -> Elxlog.bar("write(asdf).\n") end) == "asdftrue\n"
    assert capture_io(fn -> Elxlog.bar("write([1,2,3]).\n") end) == "[1,2,3]true\n"
    assert capture_io(fn -> Elxlog.bar("true().\n") end) == "true\n"
    assert capture_io(fn -> Elxlog.bar("fale().\n") end) == "false\n"
    assert capture_io(fn -> Elxlog.bar("foo(1,2,3) =.. X.\n") end) == "true\n"
    assert capture_io(fn -> Elxlog.bar("foo(1,2,3) =.. [foo;1,2,3].\n") end) == "true\n"
    assert capture_io(fn -> Elxlog.bar("X =.. [bar,1,2,3].\n") end) == "true\n"
    assert capture_io(fn -> Elxlog.bar("1 == 1.\n") end) == "true\n"
    assert capture_io(fn -> Elxlog.bar("1 == 2.\n") end) == "false\n"
    assert capture_io(fn -> Elxlog.bar("1 == 0+1.\n") end) == "true\n"
    assert capture_io(fn -> Elxlog.bar("3 >= 2.\n") end) == "true\n"
    assert capture_io(fn -> Elxlog.bar("2 >= 2.\n") end) == "true\n"
    assert capture_io(fn -> Elxlog.bar("1 >= 2.\n") end) == "false\n"
    assert capture_io(fn -> Elxlog.bar("11.1 >= 2*3.\n") end) == "true\n"
    assert capture_io(fn -> Elxlog.bar("0 >= 2-2.\n") end) == "true\n"
    assert capture_io(fn -> Elxlog.bar("3.0e1 >= 2.\n") end) == "true\n"
    assert capture_io(fn -> Elxlog.bar("3 >= 1.0e1.\n") end) == "false\n"
    assert capture_io(fn -> Elxlog.bar("3 > 2.\n") end) == "true\n"
    assert capture_io(fn -> Elxlog.bar("2 > 2.\n") end) == "false\n"
    assert capture_io(fn -> Elxlog.bar("1 > 2.\n") end) == "false\n"
    assert capture_io(fn -> Elxlog.bar("11.1 > 2*3.\n") end) == "true\n"
    assert capture_io(fn -> Elxlog.bar("0 > 2-2.\n") end) == "false\n"
    assert capture_io(fn -> Elxlog.bar("3.0e1 > 2.\n") end) == "true\n"
    assert capture_io(fn -> Elxlog.bar("3 > 1.0e1.\n") end) == "false\n"
    assert capture_io(fn -> Elxlog.bar("3 < 2.\n") end) == "false\n"
    assert capture_io(fn -> Elxlog.bar("2 < 2.\n") end) == "false\n"
    assert capture_io(fn -> Elxlog.bar("1 < 2.\n") end) == "true\n"
    assert capture_io(fn -> Elxlog.bar("11.1 < 2*3.\n") end) == "false\n"
    assert capture_io(fn -> Elxlog.bar("0 < 2-2.\n") end) == "false\n"
    assert capture_io(fn -> Elxlog.bar("3.0e1 < 2.\n") end) == "false\n"
    assert capture_io(fn -> Elxlog.bar("3 < 1.0e1.\n") end) == "true\n"
    assert capture_io(fn -> Elxlog.bar("3 <= 2.\n") end) == "false\n"
    assert capture_io(fn -> Elxlog.bar("2 <= 2.\n") end) == "true\n"
    assert capture_io(fn -> Elxlog.bar("1 <= 2.\n") end) == "true\n"
    assert capture_io(fn -> Elxlog.bar("11.1 <= 2*3.\n") end) == "false\n"
    assert capture_io(fn -> Elxlog.bar("0 <= 2-2.\n") end) == "true\n"
    assert capture_io(fn -> Elxlog.bar("3.0e1 <= 2.\n") end) == "false\n"
    assert capture_io(fn -> Elxlog.bar("3 <= 1.0e1.\n") end) == "true\n"
    assert capture_io(fn -> Elxlog.bar("3 != 2.\n") end) == "true\n"
    assert capture_io(fn -> Elxlog.bar("2 != 2.\n") end) == "false\n"
    assert capture_io(fn -> Elxlog.bar("1 != 2.\n") end) == "true\n"
    assert capture_io(fn -> Elxlog.bar("11.1 != 2*3.\n") end) == "true\n"
    assert capture_io(fn -> Elxlog.bar("0 != 2-2.\n") end) == "false\n"
    assert capture_io(fn -> Elxlog.bar("3.0e1 != 2.\n") end) == "true\n"
    assert capture_io(fn -> Elxlog.bar("3 != 1.0e1.\n") end) == "true\n"
  end
end
