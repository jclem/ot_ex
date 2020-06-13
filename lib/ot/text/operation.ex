defmodule OT.Text.Operation do
  @moduledoc """
  A list of components that iterates over and/or modifies a piece of text
  """

  @typedoc """
  An operation, which is a list consisting of `t:OT.Text.Component.retain/0`,
  `t:OT.Text.Component.insert/0`, and `t:OT.Text.Component.delete/0` components
  """
  @type t :: [binary | integer()]
end
