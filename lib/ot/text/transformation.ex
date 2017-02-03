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
  @spec transform(Operation.t, Operation.t, OT.Type.side) :: Operation.t
  def transform(op_a, op_b, side) do
    {op_a, op_b}
    |> next
    |> do_transform(side)
  end

  @spec do_transform(Scanner.output, OT.Type.side, Operation.t) :: Operation.t
  defp do_transform(next_pair, side, result \\ [])

  # Operation A is exhausted
  defp do_transform({{nil, _}, _}, _, result) do
    result
  end

  # Operation B is exhausted
  defp do_transform({{head_a, tail_a}, {nil, _}}, _, result) do
    result
    |> Operation.append(head_a)
    |> Operation.join(tail_a)
  end

  # insert / insert / left
  defp do_transform({{head_a = %{i: _}, tail_a},
                     {head_b = %{i: _}, tail_b}}, :left, result) do
    {tail_a, [head_b | tail_b]}
    |> next
    |> do_transform(Operation.append(result, head_a))
  end

  # insert / insert / left
  defp do_transform({{head_a = %{i: _}, tail_a},
                     {head_b = %{i: _}, tail_b}}, :right, result) do
    {[head_a | tail_a], [head_b | tail_b]}
    |> next
    |> do_transform(Operation.append(result, Component.length(head_b)))
  end

  # insert / retain
  defp do_transform({{head_a = %{i: _}, tail_a},
                     {head_b, tail_b}}, _, result) when is_integer(head_b) do
    {tail_a, [head_b | tail_b]}
    |> next
    |> do_transform(Operation.append(result, head_a))
  end

  # insert / delete
  defp do_transform({{head_a = %{i: _}, tail_a},
                     {head_b = %{d: _}, tail_b}}, _, result) do
    {tail_a, [head_b | tail_b]}
    |> next
    |> do_transform(Operation.append(result, head_a))
  end

  # retain / insert
  defp do_transform({{head_a, tail_a},
                     {head_b = %{i: _}, tail_b}}, _, result)
       when is_integer(head_a) do
    {[head_a | tail_a], tail_b}
    |> next
    |> do_transform(Operation.append(result, Component.length(head_b)))
  end

  # retain / retain
  defp do_transform({{head_a, tail_a},
                     {head_b, tail_b}}, _, result)
       when is_integer(head_a) and is_integer(head_b) do
    {tail_a, tail_b}
    |> next
    |> do_transform(Operation.append(result, head_a))
  end

  # retain / delete
  defp do_transform({{head_a, tail_a},
                     {%{d: _}, tail_b}}, _, result) when is_integer(head_a) do
    {tail_a, tail_b}
    |> next
    |> do_transform(result)
  end

  # delete / insert
  defp do_transform({{head_a = %{d: _}, tail_a},
                     {head_b = %{i: _}, tail_b}}, _, result) do
    {[head_a | tail_a], tail_b}
    |> next
    |> do_transform(Operation.append(result, Component.length(head_b)))
  end

  # delete / retain
  defp do_transform({{head_a = %{d: _}, tail_a},
                     {head_b, tail_b}}, _, result) when is_integer(head_b) do
    {tail_a, tail_b}
    |> next
    |> do_transform(Operation.append(result, head_a))
  end

  # delete / delete
  defp do_transform({{%{d: _}, tail_a},
                     {%{d: _}, tail_b}}, _, result) do
    {tail_a, tail_b}
    |> next
    |> do_transform(result)
  end

  @spec next(Scanner.input) :: Scanner.output
  defp next(scanner_input), do: Scanner.next(scanner_input, :insert)
end
