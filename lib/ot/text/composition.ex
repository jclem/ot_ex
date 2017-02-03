defmodule OT.Text.Composition do
  @moduledoc """
  The composition of two non-concurrent operations into a single operation.
  """

  alias OT.Text.{Operation, Scanner}

  @doc """
  Compose two operations into a single equivalent operation.

  The operations are composed in such a way that the resulting operation has the
  same effect on document state as applying one operation and then the other:
  *S ○ compose(Oa, Ob) = S ○ Oa ○ Ob*.

  ## Examples

      iex> OT.Text.Composition.compose([%{i: "Bar"}], [%{i: "Foo"}])
      [%{i: "FooBar"}]
  """
  @spec compose(Operation.t, Operation.t) :: Operation.t
  def compose(op_a, op_b) do
    {op_a, op_b}
    |> next
    |> do_compose
  end

  @spec do_compose(Scanner.output, Operation.t) :: Operation.t
  defp do_compose(next_pair, result \\ [])

  # Both operations are exhausted.
  defp do_compose({{nil, _}, {nil, _}}, result),
    do: result

  # A is exhausted.
  defp do_compose({{nil, _}, {head_b, tail_b}}, result) do
    result
    |> Operation.append(head_b)
    |> Operation.join(tail_b)
  end

  # B is exhausted.
  defp do_compose({{head_a, tail_a}, {nil, _}}, result) do
    result
    |> Operation.append(head_a)
    |> Operation.join(tail_a)
  end

  # _ / insert
  defp do_compose({{head_a, tail_a},
                   {head_b = %{i: _}, tail_b}}, result) do
    {[head_a | tail_a], tail_b}
    |> next
    |> do_compose(Operation.append(result, head_b))
  end

  # insert / retain
  defp do_compose({{head_a = %{i: _}, tail_a},
                   {retain_b, tail_b}}, result) when is_integer(retain_b) do
    {tail_a, tail_b}
    |> next
    |> do_compose(Operation.append(result, head_a))
  end

  # insert / delete
  defp do_compose({{%{i: _}, tail_a}, {%{d: _}, tail_b}}, result) do
    {tail_a, tail_b}
    |> next
    |> do_compose(result)
  end

  # retain / retain
  defp do_compose({{retain_a, tail_a}, {retain_b, tail_b}}, result)
       when is_integer(retain_a) and is_integer(retain_b) do
    {tail_a, tail_b}
    |> next
    |> do_compose(Operation.append(result, retain_a))
  end

  # retain / delete
  defp do_compose({{retain_a, tail_a},
                   {head_b = %{d: _}, tail_b}}, result)
       when is_integer(retain_a) do
    {tail_a, tail_b}
    |> next
    |> do_compose(Operation.append(result, head_b))
  end

  # delete / retain
  defp do_compose({{head_a = %{d: _}, tail_a},
                   {retain_b, tail_b}}, result)
       when is_integer(retain_b) do
    {tail_a, [retain_b | tail_b]}
    |> next
    |> do_compose(Operation.append(result, head_a))
  end

  # delete / delete
  defp do_compose({{head_a = %{d: _}, tail_a},
                   {head_b = %{d: _}, tail_b}}, result) do
    {tail_a, [head_b | tail_b]}
    |> next
    |> do_compose(Operation.append(result, head_a))
  end

  @spec next(Scanner.input) :: Scanner.output
  defp next(scanner_input), do: Scanner.next(scanner_input, :delete)
end
