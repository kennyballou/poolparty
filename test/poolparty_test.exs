defmodule PoolPartyTest do
  use ExUnit.Case, aysnc: false

  setup do
    {:ok, pool} = PoolParty.start(nil, nil)
    on_exit(pool, fn -> Application.stop(pool) end)
    {:ok, pool: pool}
  end

  test "pool can perform work", %{pool: _} do
    :timer.sleep(100)
    [:ok, :ok, :ok, :ok, :ok, :ok, :ok, :ok] =
    (1..8) |>
    Enum.map(fn(x) -> PoolParty.Scheduler.process(&(&1*&1), x, self()) end)
    :timer.sleep(100)
    state = :sys.get_state(PoolParty.Scheduler)
    assert_receive {:result, 1}
    assert_receive {:result, 4}
    assert_receive {:result, 9}
    assert_receive {:result, 16}
    assert_receive {:result, 25}
    assert_receive {:result, 36}
    assert_receive {:result, 49}
    assert_receive {:result, 64}
    assert(state.max_pool_size == Application.get_env(:poolparty, :pool_size))
    assert(length(state.queue) == 0)
  end

  test "pool queues work when full", %{pool: _} do
    :timer.sleep(100)
    (1..16) |>
    Enum.map(fn(x) ->
      PoolParty.Scheduler.process(
        fn(x) ->
          :timer.sleep(100)
          x
        end,
      x, self()) end)
    state = :sys.get_state(PoolParty.Scheduler)
    assert(length(state.queue) == 8)
    assert(HashDict.size(state.processing) == 8)
  end

  test "pool can handle worker leaving", %{pool: _} do
    :timer.sleep(100)
    PoolParty.Scheduler.process(fn(_)-> exit(:kill) end, [], self())
    assert(HashDict.size(:sys.get_state(PoolParty.Scheduler).processing) == 1)
    :timer.sleep(100)
    state = :sys.get_state(PoolParty.Scheduler)
    assert_receive {:result, :failed}
    assert(length(state.workers) == 8)
    assert(HashDict.size(state.processing) == 0)
  end

  test "pool handles leaving process without fail", %{pool: _} do
    :timer.sleep(100)
    PoolParty.Scheduler.leave(self())
  end
end
