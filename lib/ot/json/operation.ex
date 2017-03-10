defmodule OT.JSON.Operation do
  @moduledoc """
  A list of components that modifies a JSON datum.
  """

  alias OT.JSON.Component

  @typedoc """
  An operation, which is a list of `t:OT.JSON.Component.t/0`s
  """
  @type t :: [Component.t]

  @doc """
  Invert an operation.

  ## Example

      iex> OT.JSON.Operation.invert([%{p: [0], ld: "foo"}])
      [%{p: [0], li: "foo"}]
  """
  @spec invert(t) :: t
  def invert(op) do
    Enum.reduce(op, [], &([Component.invert(&1) | &2]))
  end
end
