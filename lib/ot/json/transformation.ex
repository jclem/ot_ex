defmodule OT.JSON.Transformation do
  @moduledoc """
  The transformation of two concurrent operations such that the transformed
  operation becomes causally dependent on the transforming operation.
  """

  alias OT.JSON.Operation

  @doc """
  Transform an operation against another concurrent operation.

  See `OT.Text.Transformation.transform/3` for a more complete explanation of
  operation transformation.
  """
  @spec transform(Operation.t, Operation.t, OT.Type.side) :: Operation.t
  def transform(op_a, op_b, side) do
    Enum.reduce(op_a, [], fn (comp_a, new_op) ->
      comp_a = Enum.reduce(op_b, comp_a, &do_transform(&2, &1, side))
      [comp_a | new_op]
    end)
    |> Enum.reverse
  end
end
