defmodule OT.Text do
  @moduledoc """
  A [TP1][tp1] operational transformation implementation based heavily on
  [ot-text][ot_text], but modified to be invertable.

  In this OT type, operations are represented as traversals of an entire string,
  with any final retain components implicit. This means that given the text
  "Foz Baz", the operation needed to change it to "Foo Bar Baz" would be
  represented thusly:

  ```elixir
  [2, %{d: "z"}, %{i: "o Bar"}]
  ```

  Notice that the final retain component, `4` (to skip over " Baz") is
  implicit and it not included.

  [tp1]: https://en.wikipedia.org/wiki/Operational_transformation#Convergence_properties
  [ot_text]: https://github.com/ottypes/text/blob/76870df362a1ecb615b15429f1cd6e6b99349542/lib/text.js
  """

  @behaviour OT.Type

  @typedoc "A string that this OT type can operate on"
  @type datum :: String.t

  @doc """
  Initialize a blank text datum.
  """
  @spec init :: datum
  def init, do: ""

  defdelegate apply(text, op), to: OT.Text.Application
  defdelegate apply!(text, op), to: OT.Text.Application
  defdelegate compose(op_a, op_b), to: OT.Text.Composition
  defdelegate invert(op), to: OT.Text.Operation
  defdelegate transform(op_a, op_b, side), to: OT.Text.Transformation

  @doc false
  @spec init_random(non_neg_integer) :: datum
  def init_random(length \\ 64) do
    length
    |> :crypto.strong_rand_bytes
    |> Base.url_encode64
    |> String.slice(0, length)
  end

  defdelegate apply(text, op), to: OT.Text.Application
  defdelegate apply!(text, op), to: OT.Text.Application
  defdelegate compose(op_a, op_b), to: OT.Text.Composition
  defdelegate invert(op), to: OT.Text.Operation
  defdelegate transform(op_a, op_b, side), to: OT.Text.Transformation

  @doc false
  defdelegate random_op(text), to: OT.Text.Operation, as: :random
end
