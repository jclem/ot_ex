defmodule OT.JSON.CompositionTest do
  use ExUnit.Case, async: true

  doctest OT.JSON.Composition

  alias OT.JSON.Composition

  test "composes two operations by concatenating them" do
    op_a = [%{p: [0], od: 1}]
    op_b = [%{p: [0], oi: 2}]
    assert Composition.compose(op_a, op_b) == op_a ++ op_b
  end
end
