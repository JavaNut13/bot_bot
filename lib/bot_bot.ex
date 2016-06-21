defmodule BotBot.Rtm do
  @token Application.get_env(:bot_bot, :bot_token)
  use Slack

  def start(_mode, []) do
    BotBot.Store.new :user_store
    start_link @token, []
  end

  def handle_connect(slack, state) do
    IO.puts "Connected as #{slack.me.name}"
    {:ok, state}
  end

  def handle_message(msg = %{type: "message"}, slack, state) do
    cond do
      msg.user == slack.me.id ->
        nil
      Regex.match?(~r/pair,? please/i, msg.text)
      and
      Regex.match?(~r/mr[\- ]?\d+/i, msg.text) ->
        [_, mr_number | _ ] = Regex.run ~r/mr[\- ]?(\d+)/i, msg.text
        pair = pair_users(slack.users[msg.user], slack.users)
        message = Enum.join(pair, ", ")
                    <>
                  merge_request_message(mr_number)
        send_message message, msg.channel, slack

        Process.whereis(:user_store)
        |> BotBot.Store.set_users(mr_number, pair)
      Regex.match? ~r/pair,? please/i, msg.text ->
        send_message pair_message(slack.users[msg.user], slack.users), msg.channel, slack
      Regex.match? ~r/mr[\- ]?\d+/i, msg.text ->
        [_, mr_number | _ ] = Regex.run ~r/mr[\- ]?(\d+)/i, msg.text
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
    pair_users(user, users)
    |> Enum.join(", ")
  end

  defp pair_users(%{id: user_id}, users) do
    # Remove the keys, we only want the values
    Stream.map(users, fn {_, usr} -> usr end)
    # Get rid of the current user
    |> Stream.filter(fn
       %{id: ^user_id} -> false
       _ -> true
    end)
    # Get rid of users that we don't care about
    |> Stream.filter(&real_user?/1)
    # Get their names with @ infront of them
    |> Stream.map(fn %{name: name} -> "@" <> name end)
    # Only get two users
    |> Enum.take_random(2)
  end

  defp real_user?(user) do
    case user do
      %{is_bot: true} -> false
      %{profile: %{first_name: "slackbot"}} -> false
      %{deleted: true} -> false
      _ -> true
    end
  end

  defp merge_request_message(number) do
    BotBot.Elephant.link_for number
  end
end
