defmodule PoolParty.Pool.Supervisor do
  use Supervisor
  require Logger

  def start_link(pool_size, opts \\ []) do
    Logger.debug("[#{__MODULE__}]: Starting Work Pool Supervisor")
    Supervisor.start_link(__MODULE__, {pool_size}, opts)
  end

  def init({pool_size}) do
    Logger.debug("[#{__MODULE__}]: Initializing Work Pool Supervisor")
    children = (1..pool_size) |>
    Enum.map(fn (id) ->
      Logger.debug("[#{__MODULE__}]: Starting child worker: #{id}")
      worker(PoolParty.Pool.Worker, [], id: id)
    end)
    supervise(children, strategy: :one_for_one)
  end

end
