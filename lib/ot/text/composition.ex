defmodule OT.Text.Composition do
  @moduledoc """
  The composition of two non-concurrent operations into a single operation.
  """

  @doc """
  Compose two operations into a single equivalent operation.

  The operations are composed in such a way that the resulting operation has the
  same effect on document state as applying one operation and then the other:
  *S ○ compose(Oa, Ob) = S ○ Oa ○ Ob*.

  ## Example

      iex> OT.Text.Composition.compose([%{i: "Bar"}], [%{i: "Foo"}])
      [%{i: "FooBar"}]
  """
  def compose(op_a, op_b) do
    Elixir.Rust.OT.compose(op_a, op_b)
  end

  @spec compose(Operation.t(), [Operation.t()]) :: {:ok, Operation.t()} | {:error, binary}
  def compose_many(op_a, ops) do
    Elixir.Rust.OT.compose_many(op_a, ops)
  end
end
