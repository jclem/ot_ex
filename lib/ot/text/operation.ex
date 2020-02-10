defmodule OT.Text.Operation do
  @moduledoc """
  A list of components that iterates over and/or modifies a piece of text
  """

  alias OT.Text.Component

  @typedoc """
  An operation, which is a list consisting of `t:OT.Text.Component.retain/0`,
  `t:OT.Text.Component.insert/0`, and `t:OT.Text.Component.delete/0` components
  """
  @type t :: [Component.t()]

  @doc """
  Append a component to an operation.

  ## Example

      iex> OT.Text.Operation.append([%{i: "Foo"}], %{i: "Bar"})
      [%{i: "FooBar"}]
  """
  @spec append(t, Component.t()) :: t
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
  Invert an operation.

  ## Example

      iex> OT.Text.Operation.invert([4, %{i: "Foo"}])
      [4, %{d: "Foo"}]
  """
  @spec invert(t) :: t
  def invert(op), do: Enum.map(op, &Component.invert/1)

  @doc """
  Join two operations into a single operation.

  ## Example

      iex> OT.Text.Operation.join([3, %{i: "Foo"}], [%{i: "Bar"}, 4])
      [3, %{i: "FooBar"}, 4]
  """
  @spec join(t, t) :: t
  def join([], op_b), do: op_b
  def join(op_a, []), do: op_a

  def join(op_a, op_b) do
    op_a
    |> append(hd(op_b))
    |> Kernel.++(tl(op_b))
  end

  @doc false
  @spec random(OT.Text.datum()) :: t
  def random(text) do
    text
    |> do_random
    |> Enum.reverse()
  end

  @spec do_random(String.t(), t) :: t
  defp do_random(text, op \\ [])

  defp do_random("", op), do: op

  defp do_random(text, op) do
    split_index = :rand.uniform(String.length(text) + 1) - 1
    {chunk, new_text} = String.split_at(text, split_index)
    comp = Component.random(chunk)

    if Component.type(comp) == :insert do
      do_random(text, [comp | op])
    else
      do_random(new_text, [comp | op])
    end
  end
end
