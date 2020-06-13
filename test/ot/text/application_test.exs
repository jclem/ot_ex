defmodule OT.Text.ApplicationTest do
  use ExUnit.Case, async: true

  doctest OT.Text.Application

  alias OT.Text.Application

  test "applies a simple insert component" do
    assert Application.apply("Foo", [3, %{i: " Bar"}]) == {:ok, "Foo Bar"}
  end

  test "applies a simple delete component" do
    assert Application.apply("Foo Barzzz", [7, %{d: "zzz"}]) == {:ok, "Foo Bar"}
  end

  test "handles out of bound deletes well" do
    assert Application.apply("Foo", [0, %{d: "Foos"}]) ==
             {:error,
              "The operation's base length must be equal to the string's length. String length: 3, base length: 4"}
  end

  test "returns an error if a retain is too long" do
    assert Application.apply("Foo", [4]) ==
             {:error,
              "The operation's base length must be equal to the string's length. String length: 3, base length: 4"}
  end

  test "gives retain too long errors with end retains" do
    assert Application.apply("Foo", [3, %{i: " Bar"}, 3]) ==
             {:error,
              "The operation's base length must be equal to the string's length. String length: 3, base length: 6"}
  end

  test "can delete with number" do
    assert {:ok, "Foo"} == Application.apply("Foo Bar", [3, %{d: 4}])
  end

  test "detects too short operations" do
    assert {:error,
            "The operation's base length must be equal to the string's length. String length: 7, base length: 6"} ==
             Application.apply("Foo Bar", [3, %{d: "aaa"}])
  end

  test "detects correct operation length with multiple operations" do
    assert {:ok, "Foo Hello World nice"} ==
             Application.apply("Foo Bar nice", [3, %{d: "aaaa"}, %{i: " Hello World"}, 5])
  end

  test "can split empty code" do
    code = "aa"

    assert {:ok, "a"} == Application.apply(code, [1, %{d: "a"}])
  end

  test "can insert between emojis" do
    code = "👨‍❤️‍💋‍👨👨‍❤️‍💋‍👨"

    assert {:ok, "👨‍❤️‍💋‍👨👨‍❤️‍💋‍a👨"} == OT.Text.Application2.apply(code, [20, %{i: "a"}, 2])
  end

  test "handles errors" do
    code = "aa"

    assert {:error,
            "The operation's base length must be equal to the string's length. String length: 2, base length: 3"} ==
             OT.Text.Application2.apply(code, [3, "a"])
  end
end
