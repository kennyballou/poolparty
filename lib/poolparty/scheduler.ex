defmodule PoolParty.Scheduler do
  use GenServer
  require Logger

  def start_link(pool_size, event_manager, opts \\ []) do
    Logger.debug("[#{__MODULE__}]: Starting Pool Scheduler")
    GenServer.start_link(
      __MODULE__,
      {pool_size, event_manager},
      [name: __MODULE__] ++ opts)
  end

  def init({pool_size, event_manager}) do
    Logger.debug("[#{__MODULE__}]: Initializing Pool Scheduler")
    {:ok, %{max_pool_size: pool_size,
            workers: [],
            queue: [],
            processing: HashDict.new(),
            events: event_manager}
    }
  end

  def join(worker_pid) do
    Logger.debug("[#{__MODULE__}]: Worker joining pool")
    GenServer.cast(__MODULE__, {:join, worker_pid})
  end

  def ready({:result, result, worker_pid}) do
    Logger.debug("[#{__MODULE__}]: Worker jumping into the pool")
    GenServer.cast(__MODULE__, {:ready, result, worker_pid})
  end

  def leave(worker_pid) do
    Logger.debug("[#{__MODULE__}]: Worker leaving pool")
    GenServer.cast(__MODULE__, {:leave, worker_pid})
  end

  def process(func, args, from) do
    Logger.debug("[#{__MODULE__}]: Casting work request")
    GenServer.cast(__MODULE__, {:process, func, args, from})
  end

  def handle_cast({:process, func, args, from}, state) do
    Logger.debug("[#{__MODULE__}]: Work request received")
    GenEvent.notify(state.events, {:work_queued, func, args, from})
    queue = state.queue ++ [{func, args, from}]
    case length(state.workers) do
      0 ->
        Logger.debug("[#{__MODULE__}]: No workers available")
        {:noreply, %{state| queue: queue}}
      _ ->
        {queue, workers, processing} =
          schedule_process(queue, state.workers, state.processing)
        {:noreply, %{state|
                     queue: queue,
                     workers: workers,
                     processing: processing}
     }
    end
  end

  def handle_cast({:join, pid}, state) do
    Logger.debug("[#{__MODULE__}]: Worker joined pool")
    GenEvent.notify(state.events, {:worker_joining, pid})
    {:noreply, %{state| workers: [pid | state.workers]}}
  end

  def handle_cast({:leave, pid}, state) do
    Logger.debug("[#{__MODULE__}]: Worker left pool")
    GenEvent.notify(state.events, {:worker_leaving, pid})
    {:noreply, %{state| workers: state.workers -- [pid]}}
  end

  def handle_cast({:ready, result, pid}, state) do
    Logger.debug("[#{__MODULE__}]: Worker making a splash in the pool")
    {client, processing} = HashDict.pop(state.processing, pid)
    send(client, {:result, result})
    workers = [pid | state.workers]
    case length(state.queue) do
      0 ->
        {:noreply, %{state| workers: workers}}
      _ ->
        {queue, workers, processing} =
          schedule_process(state.queue, workers, processing)
        {:noreply, %{state|
                     workers: workers,
                     queue: queue,
                     processing: processing}
        }
    end
  end

  defp schedule_process(queue, workers, processing) do
    [{f, args, client} | queue] = queue
    [next | workers] = workers
    PoolParty.Pool.Worker.process(next, f, args)
    processing = HashDict.put(processing, next, client)
    {queue, workers, processing}
  end
end
