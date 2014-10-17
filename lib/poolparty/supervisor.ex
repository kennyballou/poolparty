defmodule PoolParty.Supervisor do
  use Supervisor

  def start_link(opts \\ []) do
    Supervisor.start_link(__MODULE__, {}, [name: __MODULE__] ++ opts)
  end

  def init(_) do
    pool_size = Application.get_env(:poolparty, :pool_size)
    children = [worker(PoolParty.Scheduler, [pool_size]),
                worker(PoolParty.Pool.Supervisor, [pool_size])]
    supervise(children, strategy: :one_for_one)
  end
end
