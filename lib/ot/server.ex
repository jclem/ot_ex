defmodule OT.Server do
  @moduledoc """
  Accepts incoming operations, transforms them, and persists them to storage.
  """

  use GenServer

  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  def submit(doc_id, op) do
    GenServer.call(__MODULE__, {:submit, doc_id, op})
  end

  defp insert_ot_type(key_type) do
    :ets.insert(:ot_types, key_type)
  end

  @impl true
  def init(opts) do
    :ets.new(:ot_types, [:named_table, {:read_concurrency, true}])
    Enum.each(opts[:ot_types], &insert_ot_type/1)
    {:ok, opts}
  end

  @impl true
  def handle_call({:submit, doc_id, op}, _from, opts) do
    adapter = opts[:adapter]
    result = OT.Server.Impl.submit(adapter, doc_id, op, opts[:max_retries])
    {:reply, result, opts}
  end
end
