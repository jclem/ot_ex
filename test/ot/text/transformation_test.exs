defmodule OT.Text.TransformationTest do
  use ExUnit.Case, async: true
  alias OT.Text.Transformation
  alias OT.Text.Application

  doctest OT.Text.Transformation

  require OT.Fuzzer

  test "it converts existing inserts to b side retains at the end" do
    a = [
      %{d: 7},
      %{d: 1},
      %{i: "pqjGPUs"},
      %{i: "TGt8P1Me07"},
      %{d: 1}
    ]

    b = [
      %{i: "8-g3Q1RbtAxXwAZrfAziIkJjd1PB-fcv8gd0hVy2x"},
      9,
      %{i: "Z4JMfYcG"},
      %{i: "Jip"},
      # These two need to be converted to retains
      %{i: "j0"},
      # These two need to be converted to retains
      %{i: "U"}
    ]

    expected_result = [17, %{i: "8-g3Q1RbtAxXwAZrfAziIkJjd1PB-fcv8gd0hVy2xZ4JMfYcGJipj0U"}]

    assert OT.Text.Transformation.transform(a, b, :right) == expected_result
  end

  test "can transform an operation with 2 different sides" do
    new_op = [1, %{i: "ef"}, 1]
    conc_op = [2, %{i: "vc"}]

    assert [1, %{i: "ef"}, 3] == Transformation.transform(new_op, conc_op, :left)
  end

  test "can transform an operation with 2 different sides and retain inbetween" do
    # source: abcde
    # new_op: aefbcde
    # con_op: abvccdede
    # result: aefbvccdede
    new_op = [1, %{i: "ef"}, 4]
    conc_op = [2, %{i: "vc"}, 3, %{i: "de"}]

    assert [1, %{i: "ef"}, 8] == Transformation.transform(new_op, conc_op, :left)
  end

  test "can transform an operation" do
    new_op = [2, %{i: "vc"}]
    conc_op = [1, %{i: "ef"}, 1]

    assert [4, %{i: "vc"}] == Transformation.transform(new_op, conc_op, :left)
  end

  test "exhausted A with retain B" do
    # source: abcdef
    # new_op: abacdef
    # con_op: babcdef
    # result: babacdef
    new_op = [2, %{i: "a"}, 4]
    conc_op = [%{i: "b"}, 6]

    res = Transformation.transform(new_op, conc_op, :left)
    assert res == [3, %{i: "a"}, 4]
    assert {:ok, "babacdef"} == Application.apply("babcdef", res)
  end

  test "deletions" do
    # source: abcdef
    # new_op: abacdef
    # con_op: babcdef
    # result: babacdef
    new_op = [2, %{i: "a"}, 4]
    conc_op = [%{d: 1}, 5]

    res = Transformation.transform(new_op, conc_op, :left)
    assert res == [1, %{i: "a"}, 4]
    assert {:ok, "bacdef"} == Application.apply("bcdef", res)
  end

  test "fuzz test" do
    OT.Fuzzer.transformation_fuzz(OT.Text, 1_000)
  end

  @tag :slow_fuzz
  test "slow fuzz test" do
    OT.Fuzzer.transformation_fuzz(OT.Text, 10_000)
  end
end
