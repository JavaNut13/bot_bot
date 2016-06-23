defmodule BotBot.Supervisor do
  use Supervisor
  @token Application.get_env(:bot_bot, :bot_token)

  def start(_mode, _args) do
    start_link
  end

  def start_link do
    Supervisor.start_link(__MODULE__, :ok)
  end

  def init(:ok) do
    children = [
      worker(BotBot.Rtm, [@token, []]),
      worker(BotBot.Store, [])
    ]

    supervise(children, strategy: :one_for_one)
  end
end
