defmodule OT.Server.Supervisor do
  @moduledoc """
  Supervises a pool of OT servers and creates an ETS table of OT types for them
  to share.
  """

  use Supervisor

  def start_link(opts) do
    Supervisor.start_link(__MODULE__, opts, [])
  end

  def init(opts) do
    :ets.new(:ot_types, [:named_table, {:read_concurrency, true}])
    Enum.each(opts[:ot_types], &insert_ot_type/1)

    Supervisor.init([
      child_spec(opts),
    ], strategy: :one_for_one, name: __MODULE__)
  end

  defp child_spec(opts) do
    pool_args =
      [name: {:local, :ot_worker},
       worker_module: OT.Server,
       size: opts[:pool_size] || 5,
       max_overflow: opts[:pool_max_overflow] || 2]

    :poolboy.child_spec(:worker, pool_args, opts)
  end

  defp insert_ot_type(key_type) do
    :ets.insert(:ot_types, key_type)
  end
end
