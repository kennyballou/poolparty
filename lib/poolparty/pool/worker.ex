defmodule PoolParty.Pool.Worker do
  use GenServer
  require Logger

  def start_link(opts \\ []) do
    Logger.debug("[#{__MODULE__}]: Starting worker")
    GenServer.start_link(__MODULE__, {}, opts)
  end

  def init(_) do
    Logger.debug("[#{__MODULE__}]: Initializing Worker")
    PoolParty.Scheduler.join(self)
    {:ok, nil}
  end

  def process(pid, function, args) do
    Logger.debug("[#{__MODULE__}: Casting Process request")
    GenServer.cast(pid, {:compute, function, args})
  end

  def handle_cast({:compute, function, args}, _) do
    Logger.debug("[#{__MODULE__}]: Process request received")
    PoolParty.Scheduler.ready({:result, function.(args), self})
    {:noreply, nil}
  end

end
