defmodule OT.Text do
  @moduledoc """
  A [TP1][tp1] operational transformation implementation based heavily on
  [ot-text][ot_text] by Joseph Gentle, but modified to be invertable.

  In this type, an operation is a list of components that iterate over a piece
  of text. A component represents a retain or modification of the text:

  - `5`:            Retain 5 characters of the text
  - `%{i:"Hello"}`: Insert the string "Hello"
  - `%{d:"World"}`: Delete the string "World"

  [tp1]: https://en.wikipedia.org/wiki/Operational_transformation#Convergence_properties
  [ot_text]: https://github.com/ottypes/text/blob/76870df362a1ecb615b15429f1cd6e6b99349542/lib/text.js
  """

  @behaviour OT.Type

  @typedoc "A string that this OT type can operate on"
  @type datum :: String.t

  @typedoc """
  A delete component, in which a string of zero or more characters are deleted
  from the text datum
  """
  @type delete :: %{d: datum}

  @typedoc """
  An insert component, in which a string of zero or more characters are inserted
  into the text datum
  """
  @type insert :: %{i: datum}

  @typedoc """
  A retain component, in which a number of characters in the text datum are
  skipped over.
  """
  @type retain :: non_neg_integer

  @typedoc """
  A single unit of "work" performed on a piece of text.
  """
  @type component :: delete | insert | retain

  @typedoc """
  An operation, which is a list consisting of `t:retain/0`, `t:insert/0`, and
  `t:delete/0` components
  """
  @type operation :: [component]

  @doc """
  Initialize a blank text datum.
  """
  @spec init :: datum
  def init, do: ""

  defdelegate apply(text, op), to: OT.Text.Application
end
