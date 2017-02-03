defmodule OT.Text.OperationTest do
  use ExUnit.Case, async: true

  doctest OT.Text.Operation

  alias OT.Text.Operation

  describe ".append/2" do
    test "ignores a no-op component" do
      assert Operation.append([4], 0) == [4]
    end

    test "appends a component of the same type as the last in the op" do
      assert Operation.append([4], 2) == [6]
    end

    test "appends a component of a different type as the last in the op" do
      assert Operation.append([4], %{i: "Foo"}) == [4, %{i: "Foo"}]
    end
  end

  describe ".invert/1" do
    test "inverts an operation" do
      assert Operation.invert([4, %{i: "Foo"}, %{d: "Bar"}, 3])
      [4, %{d: "Foo"}, %{i: "Bar"}, 3]
    end
  end

  describe ".join/2" do
    test "joins two operations with a common terminus type" do
      assert Operation.join([%{i: "Foo"}], [%{i: "Bar"}]) ==
             [%{i: "FooBar"}]
    end

    test "joins two operations with different terminus types" do
      assert Operation.join([%{i: "Foo"}], [%{d: "Bar"}]) ==
             [%{i: "Foo"}, %{d: "Bar"}]
    end
  end
end
