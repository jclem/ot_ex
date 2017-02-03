defmodule OT.Text.ApplicationTest do
  use ExUnit.Case, async: true

  doctest OT.Text.Application

  alias OT.Text.Application

  test "applies a simple insert component" do
    assert Application.apply("Foo", [3, %{i: " Bar"}]) == {:ok, "Foo Bar"}
  end

  test "applies a simple delete component" do
    assert Application.apply("Foo Barzzz", [7, %{d: "zzz"}]) == {:ok, "Foo Bar"}
  end

  test "applies an implicit retain at the end of an operation" do
    assert Application.apply("Foo Baz", [3, %{i: " Bar"}]) ==
           {:ok, "Foo Bar Baz"}
  end

  test "returns an error if a retain is too long" do
    assert Application.apply("Foo", [4]) == {:error, :retain_too_long}
  end

  test "returns an error if a delete does not match" do
    assert Application.apply("Fooz", [3, %{d: "x"}]) ==
           {:error, :delete_mismatch}
  end
end
