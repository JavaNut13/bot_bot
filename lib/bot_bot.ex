defmodule BotBot.Rtm do
  @token Application.get_env(:bot_bot, :bot_token)
  use Slack

  def start(_mode, []) do
    start_link @token, []
  end

  def handle_connect(slack, state) do
    IO.puts "Connected as #{slack.me.name}"
    {:ok, state}
  end

  def handle_message(msg = %{type: "message"}, slack, state) do
    IO.inspect msg
    IO.inspect slack
    cond do
      Regex.match? ~r/pair,? please/i, msg.text ->
        send_message pair_message(msg.user, slack.users), msg.channel, slack
      Regex.match? ~r/mr[\- ]?\d+/i, msg.text ->
        [mr_number | _ ] = Regex.run ~r/(\d+)/i, msg.text
        send_message merge_request_message(mr_number), msg.channel, slack
      Regex.match? ~r/what'?s open/i, msg.text ->
        BotBot.Elephant.post_message
      true ->
        nil
    end

    {:ok, state}
  end

  def handle_message(_message, _slack, state) do
    {:ok, state}
  end

  defp pair_message(user, users) do
    # Remove the keys, we only want the values
    Stream.map(users, fn {_, usr} -> usr end)
    # Get rid of the current user
    |> Stream.filter(fn
       %{"id" => ^user.id} -> false
       _ -> true
    end)
    # Get rid of users that we don't care about
    |> Stream.filter(&ignored_user?/1)
    # Get their names with @ infront of them
    |> Stream.map(fn %{"name" => name} -> "@#{name}" end)
    # Only get two users
    |> Enum.take_random(2)
    |> Enum.join(", ")
  end

  defp ignored_user?(user) do
    case user do
      %{"is_bot" => true} -> true
      %{"profile" => %{"first_name" => "slackbot"}} -> true
      %{"deleted" => true} -> true
      _ -> false
    end
  end

  defp merge_request_message(number) do
    BotBot.Elephant.link_for number
  end
end
