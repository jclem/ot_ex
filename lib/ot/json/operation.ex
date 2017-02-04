defmodule OT.JSON.Operation do
  @moduledoc """
  A list of components that modifies a JSON datum.
  """

  @typedoc """
  An operation, which is a list of `t:OT.JSON.Component.t/0`s
  """
  @type t :: [OT.JSON.Component.t]
end
