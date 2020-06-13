defmodule OT.RustTest do
  def ex_to_js_op(%{i: text}), do: text
  def ex_to_js_op(%{d: count}) when is_binary(count), do: -String.length(count)
  def ex_to_js_op(%{d: count}), do: -count
  def ex_to_js_op(x), do: x

  def ex_to_js_ot(ot) do
    Enum.map(ot, &ex_to_js_op/1)
  end

  def js_to_ex_op(text) when is_binary(text), do: %{i: text}
  # Dummy function for elixir, it expects a string of n length,
  # but doesn't use the contents. Just send a dummy
  def js_to_ex_op(num) when num < 0, do: %{d: num}
  def js_to_ex_op(x), do: x

  def js_to_ex_ot(ot) do
    Enum.map(ot, &js_to_ex_op/1)
  end

  def apply(code, op) do
    op |> ex_to_js_ot() |> Elixir.Rust.OT.apply(code)
  end

  def transform(op_a, op_b) do
    op_a_transformed = ex_to_js_ot(op_a)
    op_b_transformed = ex_to_js_ot(op_b)
    {:ok, left, right} = Elixir.Rust.OT.transform(op_a_transformed, op_b_transformed)

    {:ok, js_to_ex_ot(left), js_to_ex_ot(right)}
  end
end
