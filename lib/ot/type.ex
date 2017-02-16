defmodule OT.Type do
  @moduledoc """
  A behaviour for implementing an operational transformation type.

  An operational transformation (OT) type is a module that is able to apply
  operations on a piece of data in any order and guarantee convergence of the
  two resulting data states.
  """

  @typedoc """
  An atom indicating whether the "left" (transforming) operation was received
  later than the "right" (transformer).
  """
  @type side :: :left | :right

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

  @doc """
  Transform an operation against another operation.
  """
  @callback transform(operation_a :: list, operation_b :: list, side) :: list
end
