defmodule OT.Text.CompositionTest do
  use ExUnit.Case, async: true

  doctest OT.Text.Composition

  alias OT.Text.Composition

  require OT.Fuzzer

  test "composes an insert over an insert" do
    assert Composition.compose([%{i: "Bar"}], [%{i: "Foo"}]) ==
             [%{i: "FooBar"}]
  end

  test "composes a retain over an insert" do
    assert Composition.compose([3], [%{i: "Foo"}]) ==
             [%{i: "Foo"}, 3]
  end

  test "composes a delete over an insert" do
    assert Composition.compose([%{d: "Bar"}], [%{i: "Foo"}]) ==
             [%{i: "Foo"}, %{d: "Bar"}]
  end

  test "composes an insert over a retain" do
    assert Composition.compose([%{i: "Foo"}], [2, %{i: "Bar"}]) ==
             [%{i: "FoBaro"}]
  end

  test "composes an insert over a delete" do
    assert Composition.compose([%{i: "Foo"}], [%{d: "Foo"}]) ==
             []
  end

  test "composes a retain over a retain" do
    assert Composition.compose([3, %{i: "Foo"}], [3, %{i: "Bar"}]) ==
             [3, %{i: "BarFoo"}]
  end

  test "composes a retain over a delete" do
    assert Composition.compose([3, %{i: "Bar"}], [%{d: "Foo"}, %{i: "Baz"}]) ==
             [%{d: "Foo"}, %{i: "BazBar"}]
  end

  test "composes a delete over a retain" do
    assert Composition.compose([%{d: "Foo"}], [4]) ==
             [%{d: "Foo"}, 4]
  end

  test "composes a delete over a delete" do
    assert Composition.compose([%{d: "Foo"}], [%{d: "Bar"}]) ==
             [%{d: "FooBar"}]
  end

  test "fuzz test" do
    OT.Fuzzer.composition_fuzz(OT.Text, 1_000)
  end

  @tag :slow_fuzz
  test "slow fuzz test" do
    OT.Fuzzer.composition_fuzz(OT.Text, 10_000)
  end
end
