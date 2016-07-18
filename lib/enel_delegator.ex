defmodule BotBot.EnelDelegator do
  @usernames ["javanut13", "sfc50", "jamesb", "patricknicholls", "jonathon.garratt"]
  @slack_url Application.get_env(:bot_bot, :enel_url)

  def post_message do
    users = Enum.take_random @usernames, 2
    if is_tuesday? do
      users = Enum.filter(users, fn
         "javanut13" -> false
         _ -> true
      end)
    end
    user = hd users

    data = %{
      text: "@#{user} needs to show up!"
    }
    body = Poison.encode! data
    HTTPoison.post! @slack_url, body
  end

  defp is_tuesday? do
    {{y, m, d}, _} = :calendar.local_time
    day = :calendar.day_of_the_week y, m, d
    day == 2 # Tuesday
  end
end
