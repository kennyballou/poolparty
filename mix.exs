defmodule Poolparty.Mixfile do
  use Mix.Project

  def project do
    [app: :poolparty,
     version: "0.0.1",
     elixir: "~> 1.0",
     deps: deps]
  end

  def application do
    [applications: [:logger],
     env: [pool_size: -1]]
  end

  defp deps do
    []
  end
end
