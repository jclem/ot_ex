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
    {_a_prime, b_prime} = OT.Text.Transformation.transform(a, b)

    assert b_prime == expected_result
  end

  test "can transform an operation with 2 different sides" do
    new_op = [1, %{i: "ef"}, 1]
    conc_op = [2, %{i: "vc"}]

    {a_prime, _b_prime} = Transformation.transform(new_op, conc_op)
    assert a_prime == [1, %{i: "ef"}, 3]
  end

  test "can transform an operation with 2 different sides and retain inbetween" do
    # source: abcde
    # new_op: aefbcde
    # con_op: abvccdede
    # result: aefbvccdede
    new_op = [1, %{i: "ef"}, 4]
    conc_op = [2, %{i: "vc"}, 3, %{i: "de"}]

    {a_prime, _b_prime} = Transformation.transform(new_op, conc_op)
    assert a_prime == [1, %{i: "ef"}, 8]
  end

  test "can transform an operation" do
    new_op = [2, %{i: "vc"}]
    conc_op = [1, %{i: "ef"}, 1]

    {a_prime, _b_prime} = Transformation.transform(new_op, conc_op)
    assert a_prime == [4, %{i: "vc"}]
  end

  test "exhausted A with retain B" do
    # source: abcdef
    # new_op: abacdef
    # con_op: babcdef
    # result: babacdef
    new_op = [2, %{i: "a"}, 4]
    conc_op = [%{i: "b"}, 6]

    {a_prime, _b_prime} = Transformation.transform(new_op, conc_op)
    assert a_prime == [3, %{i: "a"}, 4]
    assert {:ok, "babacdef"} == Application.apply("babcdef", a_prime)
  end

  test "deletions" do
    # source: abcdef
    # new_op: abacdef
    # con_op: babcdef
    # result: babacdef
    new_op = [2, %{i: "a"}, 4]
    conc_op = [%{d: 1}, 5]

    {res, _} = Transformation.transform(new_op, conc_op)
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
