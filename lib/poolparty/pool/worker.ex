defmodule PoolParty.Pool.Worker do
  use GenServer

  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, {}, opts)
  end

  def init(_) do
    PoolParty.Scheduler.join(self)
    {:ok, nil}
  end

  def process(pid, function, args) do
    GenServer.cast(pid, {:compute, function, args})
  end

  def handle_cast({:compute, function, args}, _) do
    PoolParty.Scheduler.ready({:result, function.(args), self})
    {:noreply, nil}
  end

end
