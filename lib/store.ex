defmodule BotBot.Store do

  def new(name) do
    Agent.start_link fn ->
      %{}
    end, name: name
  end

  def get_users(agent, mr_number) do
    mr_number = to_i(mr_number)
    Agent.get agent, fn
      %{^mr_number => users} ->
        users
      _ ->
        nil
    end
  end

  def set_users(agent, mr_number, users) do
    Agent.update agent, fn map ->
      Map.put map, to_i(mr_number), clean(users)
    end
  end

  defp to_i(num) when is_number(num), do: num

  defp to_i(str) do
    case Integer.parse(str) do
      {num, _} -> num
      _ -> nil
    end
  end

  defp clean(users) do
    Stream.map(users, fn
     "@" <> name -> name
      name -> name
    end)
  end
end

