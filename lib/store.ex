defmodule BotBot.Store do

  def start_link do
    IO.puts "Starting store"
    Agent.start_link fn ->
      %{}
    end, name: __MODULE__
  end

  def get_users(mr_number) do
    mr_number = to_i(mr_number)
    Agent.get __MODULE__, fn
      %{^mr_number => users} ->
        users
      _ ->
        nil
    end
  end

  def set_users(mr_number, users) do
    Agent.update __MODULE__, fn map ->
      Map.put map, to_i(mr_number), clean(users)
    end
  end

  def add_users(mr_number, users) do
    cleaned = clean users
    Agent.update __MODULE__, fn map ->
      Map.update map, to_i(mr_number), cleaned, fn old_users ->
        cleaned ++ old_users
      end
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
    Enum.map(users, fn
     "@" <> name -> name
      name -> name
    end)
  end
end

