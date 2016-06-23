defmodule BotBot.Store do
  # Stores data internally as {has_changes, %{map of data}}
  @location Application.get_env(:bot_bot, :save_location)

  def start_link do
    IO.puts "Starting store"
    Agent.start_link fn ->
      load()
    end, name: __MODULE__
  end

  def persist do
    {changes, data} = Agent.get __MODULE__, &(&1)
    if changes do
      File.write!(@location, :erlang.term_to_binary(data))
    end
  end

  def get_users(mr_number) do
    mr_number = to_i(mr_number)
    Agent.get __MODULE__, fn
      {_, %{^mr_number => users}} ->
        users
      _ ->
        nil
    end
  end

  def set_users(mr_number, users) do
    Agent.update __MODULE__, fn {_, map} ->
      new_map = Map.put map, to_i(mr_number), clean(users)
      # We always have changes after an update
      {true, new_map}
    end
  end

  def add_users(mr_number, users) do
    Agent.update __MODULE__, fn {_, map} ->
      cleaned = clean users
      new_map = Map.update map, to_i(mr_number), cleaned, fn old_users ->
        cleaned ++ old_users
      end
      # Again, lots of changes
      {true, new_map}
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

  defp load do
    case File.read(@location) do
      {:ok, contents} ->
        data = :erlang.binary_to_term contents
        IO.inspect data
        {false, data}
      _ ->
        {false, %{}}
    end
  end
end

