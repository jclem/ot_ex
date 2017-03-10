defmodule OT.JSON.ApplicationTest do
  use ExUnit.Case, async: true

  doctest OT.JSON.Application

  alias OT.JSON.Application

  test "applies a complex sequence of operations" do
    datum =
      [0, "Foo Bar", "Baz", %{"Hello" => [%{"wrld" => ["world", "World"]}]}]
    op =
      [
        %{p: [0], na: 5},
        %{p: [1], ld: "Foo Bar"},
        %{p: [1], t: "text", o: [3, %{i: " Qux"}]},
        %{p: [2, "Hello", 0, "wrld"], od: ["world", "World"], oi: "World"}
      ]
    assert Application.apply(datum, op) ==
           {:ok, [5, "Baz Qux", %{"Hello" => [%{"wrld" => "World"}]}]}
  end

  test "list delete verifies deleted data" do
    datum = [0, 1, 2]
    op = [%{p: [1], ld: 3}]
    assert Application.apply(datum, op) == {:error, :delete_mismatch}
  end

  test "list replace verifies deleted data" do
    datum = [0, 1, 2]
    op = [%{p: [1], ld: 3, li: 4}]
    assert Application.apply(datum, op) == {:error, :delete_mismatch}
  end

  test "object delete verifies deleted data" do
    datum = %{foo: "bar"}
    op = [%{p: ["foo"], od: "baz"}]
    assert Application.apply(datum, op) == {:error, :delete_mismatch}
  end

  test "object replace verifies deleted data" do
    datum = %{foo: "bar"}
    op = [%{p: ["foo"], od: "baz", oi: "qux"}]
    assert Application.apply(datum, op) == {:error, :delete_mismatch}
  end
end
