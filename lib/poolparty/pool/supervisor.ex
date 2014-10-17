defmodule PoolParty.Pool.Supervisor do
  use Supervisor

  def start_link(pool_size, opts \\ []) do
    Supervisor.start_link(__MODULE__, {pool_size}, opts)
  end

  def init({pool_size}) do
    children = (1..pool_size) |>
    Enum.map(fn (id) ->
      worker(PoolParty.Pool.Worker, [], id: id)
    end)
    supervise(children, strategy: :one_for_one)
  end

end
