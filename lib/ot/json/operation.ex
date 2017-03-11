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
  Append a component to an operation.

  ## Example

      iex> OT.JSON.Operation.append([%{p: [0], na: 1}], %{p: [0], na: 1})
      [%{p: [0], na: 2}]
  """
  @spec append(t, Component.t) :: t
  def append([], comp), do: comp

  def append(op, comp) do
    last_component = List.last(op)

    op
    |> Enum.slice(0..-2)
    |> Kernel.++(Component.join(last_component, comp))
  end

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
