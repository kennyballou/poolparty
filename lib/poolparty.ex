defmodule PoolParty do
  use Application
  require Logger

  def start(_type, _args) do
    Logger.debug("[#{__MODULE__}]: Starting a Pool Party!")
    {:ok, event_manager} = GenEvent.start_link()
    PoolParty.Supervisor.start_link(event_manager)
  end
end
