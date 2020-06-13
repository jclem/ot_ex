defmodule OT.Text.CompositionTest do
  use ExUnit.Case, async: true

  doctest OT.Text.Composition

  alias OT.Text.Composition

  require OT.Fuzzer

  test "fuzz test" do
    OT.Fuzzer.composition_fuzz(OT.Text, 1_000)
  end

  @tag :slow_fuzz
  test "slow fuzz test" do
    OT.Fuzzer.composition_fuzz(OT.Text, 10_000)
  end
end
