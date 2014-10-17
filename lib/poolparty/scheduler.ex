defmodule PoolParty.Scheduler do
  use GenServer

  def start_link(pool_size, opts \\ []) do
    GenServer.start_link(
      __MODULE__,
      {pool_size},
      [name: __MODULE__] ++ opts)
  end

  def init({pool_size}) do
    {:ok, %{max_pool_size: pool_size,
            workers: [],
            queue: [],
            processing: HashDict.new()}
    }
  end

  def join(worker_pid) do
    GenServer.cast(__MODULE__, {:join, worker_pid})
  end

  def ready({:result, result, worker_pid}) do
    GenServer.cast(__MODULE__, {:ready, result, worker_pid})
  end

  def process(func, args, from) do
    GenServer.cast(__MODULE__, {:process, func, args, from})
  end

  def handle_cast({:process, func, args, from}, state) do
    queue = state.queue ++ [{func, args, from}]
    case length(state.workers) do
      0 ->
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
    {:noreply, %{state| workers: [pid | state.workers]}}
  end

  def handle_cast({:leave, pid}, state) do
    {:noreply, %{state| workers: state.workers -- [pid]}}
  end

  def handle_cast({:ready, result, pid}, state) do
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
