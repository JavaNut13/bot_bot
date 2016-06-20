defmodule Store do
  @team Application.get_env(:elephant_bot, :team)
  import Exredis.Api

  def get_client do
    {:ok, client} = Exredis.start_link
    client
  end

  def get_users(redis, mr_number) do
    case get(redis, key_for(mr_number)) do
      :undefined -> nil
      content -> Poison.decode!(content)
    end
  end

  def set_users(redis, mr_number, users) do
    set(redis, key_for(mr_number), Poison.encode! users)
  end

  defp key_for(mr_number) do
    "team:#{@team}:mr:#{mr_number}"
  end
end

