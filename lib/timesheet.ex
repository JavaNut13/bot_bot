defmodule BotBot.Timesheet do
  @elephant_timesheet "http://agilefant.cosc.canterbury.ac.nz:8080/agilefant302/generateTree.action"
  @logging_url "http://agilefant.cosc.canterbury.ac.nz:8080/agilefant302/editIteration.action?iterationId=26"
  @login_url "http://agilefant.cosc.canterbury.ac.nz:8080/agilefant302/j_spring_security_check"

  @ids_and_usernames [
    {105, "jab297"},
    {121, "javanut13"},
    {140, "jonathon.garratt"},
    {125, "leachy"},
    {154, "patricknicholls"},
    {149, "sfc50"}
  ]

  def post_message do
    times = get_all_times <>
    "\n<#{@logging_url}|Log time>"
    BotBot.Elephant.post times
  end

  def get_all_times do
    @ids_and_usernames
    |> Stream.map(fn {id, username} ->
      hours = get_data_for(id)
      "@#{username}: #{hours}"
    end)
    |> Enum.join("\n")
  end

  defp get_data_for(user_id) do
    headers = %{
      "Cookie" => get_cookies,
      "Content-Type" => "application/x-www-form-urlencoded"
    }
    data = "backlogSelectionType=0&productIds=1&projectIds=4&iterationIds=28&interval=NO_INTERVAL&startDate=&endDate=&userIds=#{user_id}"
    returned = HTTPoison.post!(@elephant_timesheet, data, headers).body
    |> Floki.find(".timesheet-header-ul .hoursum")
    
    case returned do
      [] -> "No time logged"
      [{"li", _, [time]} | _] -> time
    end
  end

  def get_cookies do
    user = Application.get_env(:bot_bot, :agilefant_username)
    pass = Application.get_env(:bot_bot, :agilefant_password)
    data = "j_username=#{user}&j_password=#{pass}&_spring_security_remember_me=on"
    headers = %{
      "Content-Type" => "application/x-www-form-urlencoded"
    }
    cookies = HTTPoison.post!(@login_url, data, headers).headers
    # Get rid of all the other headers
    |> Stream.filter(fn
      {"Set-Cookie", _} -> true
      _ -> false
    end)
    # Only get the first bit of the cookie (ie the session ID/ whatever)
    |> Stream.map(fn {"Set-Cookie", cookie} ->
      [cook | _] = String.split(cookie, "; ")
      cook
    end)
    # Join them all together into one cookie goodness
    |> Enum.join("; ")
    cookies
  end
end

