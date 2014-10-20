defmodule PoolParty.Supervisor do
  use Supervisor
  require Logger

  def start_link(opts \\ []) do
    Logger.debug("[#{__MODULE__}]: Starting Pool Party Supervisor")
    Supervisor.start_link(__MODULE__, {}, [name: __MODULE__] ++ opts)
  end

  def init(_) do
    Logger.debug("[#{__MODULE__}]: Initializing Pool Party Supervisor")
    pool_size = Application.get_env(:poolparty, :pool_size)
    Logger.debug("[#{__MODULE__}]: Pool size: #{pool_size}")
    children = [worker(PoolParty.Scheduler, [pool_size]),
                worker(PoolParty.Pool.Supervisor, [pool_size])]
    supervise(children, strategy: :one_for_one)
  end
end
