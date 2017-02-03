defmodule OT.Text do
  @moduledoc """
  A [TP1][tp1] operational transformation implementation based heavily on
  [ot-text][ot_text] by Joseph Gentle, but modified to be invertable.

  In this type, an operation is a list of components that iterate over a piece
  of text.

  [tp1]: https://en.wikipedia.org/wiki/Operational_transformation#Convergence_properties
  [ot_text]: https://github.com/ottypes/text/blob/76870df362a1ecb615b15429f1cd6e6b99349542/lib/text.js
  """

  @behaviour OT.Type

  alias __MODULE__.Component

  @typedoc "A string that this OT type can operate on"
  @type datum :: String.t

  @typedoc """
  An operation, which is a list consisting of `t:retain/0`, `t:insert/0`, and
  `t:delete/0` components
  """
  @type operation :: [Component.t]

  @doc """
  Initialize a blank text datum.
  """
  @spec init :: datum
  def init, do: ""

  defdelegate apply(text, op), to: OT.Text.Application
end
