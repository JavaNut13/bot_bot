defmodule BotBot.Rtm do
  @mr_regex ~r/mr[\- ]?(\d+)/i
  @pair_regex ~r/pair,? please/i
  @review_regex ~r/review/i
  @open_regex ~r/what.?s open/
  @user_regex ~r/<@([\w\d]+)>|@[\w\d]+/i

  use Slack

  def handle_connect(slack, state) do
    IO.puts "Connected as #{slack.me.name}"
    {:ok, state}
  end

  defp respond_to(msg, slack) do
    cond do
      Regex.match?(@pair_regex, msg.text)
      and
      Regex.match?(@mr_regex, msg.text) ->
        [_, mr_number | _ ] = Regex.run @mr_regex, msg.text
        pair = pair_users(slack.users[msg.user], slack.users)
        message = Enum.join(pair, ", ") <> " "
                    <>
                  merge_request_message(mr_number)
        send_message message, msg.channel, slack

        BotBot.Store.set_users(mr_number, pair)
      Regex.match? @pair_regex, msg.text ->
        send_message pair_message(slack.users[msg.user], slack.users), msg.channel, slack
      Regex.match?(@review_regex, msg.text) and Regex.match?(@mr_regex, msg.text)
      and Regex.match?(@user_regex, msg.text) ->
        users = Regex.scan(@user_regex, msg.text)
        |> Stream.map(fn
          [_, id] -> lookup_user_name(id, slack)
          [user] -> user
          _ -> nil
        end)
        |> Enum.filter(fn
          nil -> false
          _ -> true
        end)
        
        [_, mr_number | _ ] = Regex.run @mr_regex, msg.text
        
        BotBot.Store.add_users mr_number, users

        send_message ":sparkles:", msg.channel, slack
      Regex.match? @mr_regex, msg.text ->
        [_, mr_number | _ ] = Regex.run @mr_regex, msg.text
        send_message merge_request_message(mr_number), msg.channel, slack
      Regex.match? @open_regex, msg.text ->
        BotBot.Elephant.post_message
      true ->
        nil
    end
  end

  def handle_message(msg = %{type: "message"}, slack, state) do
    unless msg.user == slack.me.id do
      try do
        respond_to msg, slack
      rescue
        error ->
          send_message "Oh poop: #{inspect error}", msg.channel, slack
      end
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
