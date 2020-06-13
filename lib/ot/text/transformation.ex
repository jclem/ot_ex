defmodule OT.Text.Transformation do
  @moduledoc """
  The transformation of two concurrent operations such that they satisfy the
  [TP1][tp1] property of operational transformation.

  [tp1]: https://en.wikipedia.org/wiki/Operational_transformation#Convergence_properties
  """

  alias OT.Text.{Component, Operation, Scanner}

  @doc """
  Transform an operation against another operation.

  Given an operation A that occurred at the same time as operation B against the
  same text state, transform the components of operation A such that the state
  of the text after applying operation A and then operation B is the same as
  after applying operation B and then the transformation of operation A against
  operation B:

  *S ○ Oa ○ transform(Ob, Oa) = S ○ Ob ○ transform(Oa, Ob)*

  This function also takes a third `side` argument that indicates which
  operation came later. This is important when deciding whether it is acceptable
  to break up insert components from one operation or the other.
  """

  # @spec transform(Operation.t(), Operation.t(), OT.Type.side()) :: Operation.t()
  # def transform(op_a, op_b, side) do
  #   {op_a, op_b}
  #   |> next
  #   |> do_transform(side)
  # end

  def transform(op_a, op_b) do
    Elixir.Rust.OT.transform(op_a, op_b)
  end
end
