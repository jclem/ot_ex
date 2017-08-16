defmodule OT.Server do
  @moduledoc """
  Accepts incoming operations, transforms them, and persists them to storage.
  """

  use GenServer

  @doc false
  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts)
  end

  @doc """
  Submit an operation to one of a pool of OT workers.
  """
  def submit(datum_id, op) do
    :poolboy.transaction(:ot_worker, fn worker ->
      GenServer.call(worker, {:submit, datum_id, op})
    end)
  end

  @impl true
  def handle_call({:submit, datum_id, op}, _from, opts) do
    adapter = opts[:adapter]
    result = OT.Server.Impl.submit(adapter, datum_id, op, opts[:max_retries])
    {:reply, result, opts}
  end
end
