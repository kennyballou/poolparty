defmodule PoolParty.Pool.Worker do
  use GenServer
  require Logger

  def start_link(event_manager, opts \\ []) do
    Logger.debug("[#{__MODULE__}]: Starting worker")
    GenServer.start_link(__MODULE__, {event_manager}, opts)
  end

  def init({event_manager}) do
    Logger.debug("[#{__MODULE__}]: Initializing Worker")
    PoolParty.Scheduler.join(self)
    {:ok, %{events: event_manager}}
  end

  def process(pid, function, args) do
    Logger.debug("[#{__MODULE__}: Casting Process request")
    GenServer.cast(pid, {:compute, function, args})
  end

  def handle_cast({:compute, function, args}, state) do
    Logger.debug("[#{__MODULE__}]: Process request received")
    PoolParty.Scheduler.ready({:result, function.(args), self})
    {:noreply, state}
  end

  def terminate(reason, state) do
    Logger.debug("[#{__MODULE__}]: Pool Worker terminating")
    PoolParty.Scheduler.leave(self())
    super(reason, state)
  end

end
