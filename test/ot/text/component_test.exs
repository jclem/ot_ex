defmodule OT.Text.ComponentTest do
  use ExUnit.Case, async: true

  doctest OT.Text.Component

  alias OT.Text.Component

  describe ".length/1" do
    test "determines the length of a delete" do
      assert Component.length(%{d: "Foo"}) == 3
    end

    test "determines the length of an insert" do
      assert Component.length(%{i: "Hello"}) == 5
    end

    test "determines the length of a retain" do
      assert Component.length(4) == 4
    end
  end

  describe ".type/1" do
    test "determines the type of a delete" do
      assert Component.type(%{d: "Foo"}) == :delete
    end

    test "determines the type of an insert" do
      assert Component.type(%{i: "Hello"}) == :insert
    end

    test "determines the type of a retain" do
      assert Component.type(4) == :retain
    end
  end

  describe ".join/2" do
    test "joins two retains" do
      assert Component.join(4, 2) == [6]
    end

    test "joins two inserts" do
      assert Component.join(%{i: "Foo"}, %{i: "Bar"}) == [%{i: "FooBar"}]
    end

    test "joins two deletes" do
      assert Component.join(%{d: "Foo"}, %{d: "Bar"}) == [%{d: "FooBar"}]
    end
  end

  describe ".compare/2" do
    test "compares two components" do
      comp_a = 4
      comp_b = %{i: "Hello"}
      comp_c = %{d: "Hello"}

      assert Component.compare(comp_a, comp_b) == :lt
      assert Component.compare(comp_b, comp_a) == :gt
      assert Component.compare(comp_b, comp_c) == :eq
    end
  end

  describe ".split/2" do
    test "splits a delete" do
      assert Component.split(%{d: "Foo"}, 2) == {%{d: "Fo"}, %{d: "o"}}
    end

    test "splits an insert" do
      assert Component.split(%{i: "Hello"}, 3) == {%{i: "Hel"}, %{i: "lo"}}
    end

    test "splits a retain" do
      assert Component.split(4, 1) == {1, 3}
    end
  end
end
