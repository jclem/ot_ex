defmodule OT.Server.Adapter do
  @type datum_id :: any
  @type datum :: %{content: any}
  @type op :: %{String.t => any}

  @callback transact((... -> any)) :: {:ok, any} | {:error, any}
  @callback rollback(any) :: no_return
  @callback handle_submit_error(any, datum_id, op) :: :retry | {:error, any}
  @callback get_datum(datum_id) :: {:ok, datum}
  @callback get_conflicting_operations(datum, non_neg_integer) :: [op]
  @callback update_datum(datum, any) :: {:ok, any} | {:error, any}
  @callback insert_operation(datum, op) :: {:ok, op} | {:error, any}
end
