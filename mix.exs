defmodule BotBot.Mixfile do
  use Mix.Project

  def project do
    [
      app: :bot_bot,
      version: "0.0.1",
      elixir: "~> 1.2",
      build_embedded: Mix.env == :prod,
      start_permanent: Mix.env == :prod,
      deps: deps
    ]
  end

  def application do
    [
      mod: {BotBot.Supervisor, []},
      applications: [
        :logger,
        :quantum,
        :httpoison,
        :slack,
        :poison,
        :floki,
        :websocket_client
      ]
    ]
  end

  defp deps do
    [
      {:httpoison, "~> 0.8.0"},
      {:poison, "~> 2.0"},
      {:quantum, ">= 1.7.1"},
      {:slack, "~> 0.6.0"},
      {:websocket_client, git: "https://github.com/jeremyong/websocket_client"},
      {:floki, "~> 0.8.1"},
      {:exrm, "~> 1.0.6"}
    ]
  end
end
