defmodule OT.Server.Impl do
  @moduledoc """
  Implements the actual business logic of OT.Server.
  """

  @doc """
  Submit an operation, transforming it against concurrent operations, if
  necessary.
  """
  def submit(adapter, datum_id, op, max_retries, retries \\ 0)

  def submit(_, _, _, max_retries, retries) when retries > max_retries do
    {:error, :max_retries_exceeded}
  end

  def submit(adapter, datum_id, op, max_retries, retries) do
    do_submit(adapter, datum_id, op, max_retries, retries)
  end

  defp do_submit(adapter, datum_id, op, max_retries, retries) do
    txn_result =
      adapter.transact(fn ->
        case attempt_submit(adapter, datum_id, op) do
          {:ok, new_op} -> new_op
          {:error, error} -> adapter.rollback(error)
        end
      end)

    case txn_result do
      {:ok, new_op} ->
        {:ok, new_op}
      {:error, err} ->
        adapter.handle_submit_error(err, datum_id, op)
        |> case do
          :retry -> submit(adapter, datum_id, op, max_retries, retries + 1)
          err -> err
        end
    end
  end

  defp attempt_submit(adapter, datum_id, op) do
    with {:ok, datum} <- adapter.get_datum(datum_id),
         {:ok, type}  <- get_type(datum.type),
         :ok          <- check_datum_version(datum, op),
         op           =  get_new_op(adapter, datum, op, type),
         {:ok, datum} <- update_datum(adapter, datum, op, type),
         {:ok, op}    <- insert_op(adapter, datum, op) do
      {:ok, op}
    end
  end

  defp check_datum_version(datum, op) do
    if op["version"] > datum.version + 1 do
      {:error, {:version_mismatch, op["version"], datum.version}}
    else
      :ok
    end
  end

  defp get_new_op(adapter, datum, op, type) do
    adapter.get_conflicting_operations(datum, op["version"])
    |> case do
      [] ->
        op
      conflicting_ops when is_list(conflicting_ops) ->
        new_vsn = Enum.max_by(conflicting_ops, &(&1.version)).version + 1

        op
        |> Map.put("version", new_vsn)
        |> Map.put("data",
          conflicting_ops
          |> Enum.map(&(&1.data))
          |> Enum.reduce(op["data"], &type.transform(&2, &1, :left)))
    end
  end

  defp get_type(type_key) do
    case :ets.lookup(:ot_types, type_key) do
      [{^type_key, type}] -> {:ok, type}
      _ -> {:error, :ot_type_not_found}
    end
  end

  defp update_datum(adapter, datum, op, type) do
    case type.apply(datum.content, op["data"]) do
      {:ok, content} ->
        adapter.update_datum(datum, content)
      error ->
        error
    end
  end

  defp insert_op(adapter, datum, op) do
    adapter.insert_operation(datum, op)
  end
end
