defmodule OT.JSON.Composition do
  @moduledoc """
  The composition of two operations where one is causally dependent on the
  other.
  """

  alias OT.JSON.Operation

  @doc """
  Compose two operations into a single equivalent operation.

  ## Example

  iex> OT.JSON.Composition.compose([%{p: [0], ld: 1}], [%{p: [1], ld: 2}])
  [%{p: [0], ld: 1}, %{p: [1], ld: 2}]
  """
  @spec compose(Operation.t, Operation.t) :: Operation.t
  def compose(op_a, op_b) do
    Enum.reduce(op_b, op_a, &Operation.append(&2, &1))
  end
end
