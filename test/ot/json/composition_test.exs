defmodule OT.JSON.CompositionTest do
  use ExUnit.Case, async: true

  doctest OT.JSON.Composition

  alias OT.JSON.Composition

  test "composes two operations" do
    op_a = [%{p: [0], od: 1, oi: 2}]
    op_b = [%{p: [0], od: 2, oi: 3}]
    assert Composition.compose(op_a, op_b) == [%{p: [0], od: 1, oi: 3}]
  end
end
