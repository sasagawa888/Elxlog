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
    assert capture_io(fn -> Elxlog.bar("length([1,2,3],X).\n") end) == "true\n"
    assert capture_io(fn -> Elxlog.bar("length([1,2,3],3).\n") end) == "true\n"
    assert capture_io(fn -> Elxlog.bar("length([1,2,3],4).\n") end) == "false\n"
  end
end
