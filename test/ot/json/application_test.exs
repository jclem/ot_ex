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
           [5, "Baz Qux", %{"Hello" => [%{"wrld" => "World"}]}]
  end
end
