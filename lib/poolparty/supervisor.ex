defmodule PoolParty.Supervisor do
  use Supervisor
  require Logger

  def start_link(event_manager, opts \\ []) do
    Logger.debug("[#{__MODULE__}]: Starting Pool Party Supervisor")
    Supervisor.start_link(
      __MODULE__,
      {event_manager},
      [name: __MODULE__] ++ opts)
  end

  def init({event_manager}) do
    Logger.debug("[#{__MODULE__}]: Initializing Pool Party Supervisor")
    pool_size = Application.get_env(:poolparty, :pool_size)
    Logger.debug("[#{__MODULE__}]: Pool size: #{pool_size}")
    children = [worker(PoolParty.Scheduler, [pool_size, event_manager]),
                supervisor(PoolParty.Pool.Supervisor,
                           [pool_size, event_manager])]
    supervise(children, strategy: :one_for_one)
  end
end
