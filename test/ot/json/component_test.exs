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

  describe ".join/2" do
    test "joins components with non-matching paths" do
      assert Component.join(%{p: [0], na: 1}, %{p: [1], na: 1}) ==
        [%{p: [0], na: 1}, %{p: [1], na: 1}]
    end

    test "joins to text subtype ops" do
      assert Component.join(%{p: [0], t: "text", o: [%{i: "foo"}]},
                            %{p: [0], t: "text", o: [%{i: "bar"}]}) ==
        [%{p: [0], t: "text", o: [%{i: "barfoo"}]}]
    end

    test "joins two number adds" do
      assert Component.join(%{p: [0], na: 1}, %{p: [0], na: 2}) ==
        [%{p: [0], na: 3}]
    end

    test "joins a list replace and a list replace" do
      assert Component.join(%{p: [0], ld: 0, li: 1}, %{p: [0], ld: 1, li: 2}) ==
        [%{p: [0], ld: 0, li: 2}]
    end

    test "joins a list replace and a list delete" do
      assert Component.join(%{p: [0], ld: 0, li: 1}, %{p: [0], ld: 1}) ==
        [%{p: [0], ld: 0}]
    end

    test "joins a list replace and a list insert" do
      assert Component.join(%{p: [0], ld: 0, li: 1}, %{p: [0], li: 2}) ==
        [%{p: [0], ld: 0, li: 1}, %{p: [0], li: 2}]
    end

    test "joins a list delete and a list replace" do
      assert Component.join(%{p: [0], ld: 0}, %{p: [0], ld: 1, li: 2}) ==
        [%{p: [0], ld: 0}, %{p: [0], ld: 1, li: 2}]
    end

    test "joins a list delete and a list delete" do
      assert Component.join(%{p: [0], ld: 0}, %{p: [0], ld: 1}) ==
        [%{p: [0], ld: 0}, %{p: [0], ld: 1}]
    end

    test "joins a list delete and a list insert" do
      assert Component.join(%{p: [0], ld: 0}, %{p: [0], li: 1}) ==
        [%{p: [0], ld: 0, li: 1}]
    end

    test "joins a list insert and a list replace" do
      assert Component.join(%{p: [0], li: 1}, %{p: [0], ld: 1, li: 2}) ==
        [%{p: [0], li: 2}]
    end

    test "joins a list insert and a list delete" do
      assert Component.join(%{p: [0], li: 1}, %{p: [0], ld: 1}) ==
        []
    end

    test "joins a list insert and a list insert" do
      assert Component.join(%{p: [0], li: 1}, %{p: [0], li: 2}) ==
        [%{p: [0], li: 1}, %{p: [0], li: 2}]
    end

    test "joins an object replace and an object replace" do
      assert Component.join(%{p: [0], od: 0, oi: 1}, %{p: [0], od: 1, oi: 2}) ==
        [%{p: [0], od: 0, oi: 2}]
    end

    test "joins an object replace and an object delete" do
      assert Component.join(%{p: [0], od: 0, oi: 1}, %{p: [0], od: 1}) ==
        [%{p: [0], od: 0}]
    end

    test "joins an object replace and an object insert" do
      assert Component.join(%{p: [0], od: 0, oi: 1}, %{p: [0], oi: 2}) ==
        [%{p: [0], od: 0, oi: 1}, %{p: [0], oi: 2}]
    end

    test "joins an object delete and an object replace" do
      assert Component.join(%{p: [0], od: 0}, %{p: [0], od: 1, oi: 2}) ==
        [%{p: [0], od: 0}, %{p: [0], od: 1, oi: 2}]
    end

    test "joins an object delete and an object delete" do
      assert Component.join(%{p: [0], od: 0}, %{p: [0], od: 1}) ==
        [%{p: [0], od: 0}, %{p: [0], od: 1}]
    end

    test "joins an object delete and an object insert" do
      assert Component.join(%{p: [0], od: 0}, %{p: [0], oi: 1}) ==
        [%{p: [0], od: 0, oi: 1}]
    end

    test "joins an object insert and an object replace" do
      assert Component.join(%{p: [0], oi: 1}, %{p: [0], od: 1, oi: 2}) ==
        [%{p: [0], oi: 2}]
    end

    test "joins an object insert and an object delete" do
      assert Component.join(%{p: [0], oi: 1}, %{p: [0], od: 1}) ==
        []
    end

    test "joins an object insert and an object insert" do
      assert Component.join(%{p: [0], oi: 1}, %{p: [0], oi: 2}) ==
        [%{p: [0], oi: 1}, %{p: [0], oi: 2}]
    end
  end
end
