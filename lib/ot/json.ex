defmodule OT.JSON do
  @moduledoc """
  A [TP1][tp1] operational transformation implementation based heavily on
  [ot-json0][ot_json] by Joseph Gentle.

  [tp1]: https://en.wikipedia.org/wiki/Operational_transformation#Convergence_properties
  [ot_json]: https://github.com/ottypes/json0/blob/8974b416c815df79428c86101ca4e3eeade1d8db/lib/json0.js
  """

  @behaviour OT.Type

  @typedoc "A map that this OT type can operate on"
  @type json_map :: %{optional(String.t) => value}

  @typedoc "A list that this OT type can operate on"
  @type json_list :: [value]

  @typedoc "A piece of data that this OT type can operate on"
  @type datum :: json_map | json_list

  @typedoc "A value of a JSON list or map"
  @type value :: datum | String.t | number | nil

  @doc """
  Initialize a blank JSON datum (defaults to map).
  """
  @spec init(:map | :list) :: %{} | []
  def init(type \\ :map)
  def init(:map), do: %{}
  def init(:list), do: []

  defdelegate apply(text, op), to: OT.JSON.Application
  defdelegate apply!(text, op), to: OT.JSON.Application
  defdelegate compose(op_a, op_b), to: OT.JSON.Composition
  defdelegate invert(op), to: OT.JSON.Operation
  # defdelegate transform(op_a, op_b, side), to: OT.JSON.Transformation
end
