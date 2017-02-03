defmodule OT.Type do
  @moduledoc """
  A behaviour for implementing an operational transformationt type.

  An operational transformation (OT) type is a module that is able to apply
  operations on a piece of data in any order and guarantee convergence of the
  two resulting data states.
  """

  @doc """
  Invoked in order to initialize a "blank" datum of the type operated on by the
  OT type.
  """
  @callback init :: any

  @doc """
  Apply an operation to a datum of the type operated on by the OT type.
  """
  @callback apply(any, list) :: any

  @doc """
  Compose two operations together into a single operation.
  """
  @callback compose(operation_a :: list, operation_b :: list) :: list
end
