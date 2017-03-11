defmodule OT.JSON.ComponentTest do
  use ExUnit.Case, async: true

  doctest OT.JSON.Component

  alias OT.JSON.Component

  describe ".invert/1" do
    test "inverts a list replace" do
      assert Component.invert(%{p: [0], ld: 1, li: 2}) ==
        %{p: [0], ld: 2, li: 1}
    end

    test "inverts a list delete" do
      assert Component.invert(%{p: [0], ld: 1}) ==
        %{p: [0], li: 1}
    end

    test "inverts a list insert" do
      assert Component.invert(%{p: [0], li: 1}) ==
        %{p: [0], ld: 1}
    end

    test "inverts a list move" do
      assert Component.invert(%{p: [0], lm: 1}) ==
        %{p: [1], lm: 0}
    end

    test "inverts an object replace" do
      assert Component.invert(%{p: ["foo"], od: 1, oi: 2}) ==
        %{p: ["foo"], od: 2, oi: 1}
    end

    test "inverts an object delete" do
      assert Component.invert(%{p: ["foo"], od: 1}) ==
        %{p: ["foo"], oi: 1}
    end

    test "inverts an object insert" do
      assert Component.invert(%{p: ["foo"], oi: 1}) ==
        %{p: ["foo"], od: 1}
    end

    test "inverts a number add" do
      assert Component.invert(%{p: [0], na: 1}) ==
        %{p: [0], na: -1}
    end

    test "inverts a text subtype" do
      assert Component.invert(%{p: [0], t: "text", o: [0, %{d: "foo"}]}) ==
        %{p: [0], t: "text", o: [0, %{i: "foo"}]}
    end
  end
end
