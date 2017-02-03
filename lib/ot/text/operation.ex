defmodule OT.Text.Operation do
  @moduledoc """
  A list of components that iterates over a piece of text, possible making
  changes to it.
  """

  alias OT.Text.Component

  @typedoc """
  An operation, which is a list consisting of `t:retain/0`, `t:insert/0`, and
  `t:delete/0` components
  """
  @type t :: [Component.t]

  @doc """
  Append a component to an operation.
  """
  @spec append(t, Component.t) :: t
  def append([], comp), do: [comp]
  def append(op, comp) do
    last_component = List.last(op)

    if Component.no_op?(comp) do
      op
    else
      op
      |> Enum.slice(0..-2)
      |> Kernel.++(Component.join(last_component, comp))
    end
  end

  @doc """
  Join two operations into a single operation.
  """
  @spec join(t, t) :: t
  def join([], op_b), do: op_b
  def join(op_a, []), do: op_a

  def join(op_a, op_b) do
    op_a
    |> append(hd(op_b))
    |> Kernel.++(tl(op_b))
  end
end
