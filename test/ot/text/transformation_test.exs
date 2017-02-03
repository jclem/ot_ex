defmodule OT.Text.TransformationTest do
  use ExUnit.Case, async: true

  doctest OT.Text.Transformation

  require OT.Fuzzer

  test "fuzz test" do
    OT.Fuzzer.transformation_fuzz(OT.Text, 1_000)
  end

  @tag :slow_fuzz
  test "slow fuzz test" do
    OT.Fuzzer.transformation_fuzz(OT.Text, 10_000)
  end
end
