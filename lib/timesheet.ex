defmodule BotBot.Timesheet do
  @elephant_timesheet "http://agilefant.cosc.canterbury.ac.nz:8080/agilefant302/generateTree.action"
  @logging_url "http://agilefant.cosc.canterbury.ac.nz:8080/agilefant302/editIteration.action?iterationId=26"

  @ids_and_usernames [
    {159, "bmosky"},
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

  def get_data_for(user_id) do
    headers = %{
      "Cookie" => "JSESSIONID=EC622D15FC1602C326BBDC82A6F4B072",
      "Content-Type" => "application/x-www-form-urlencoded"
    }
    data = "backlogSelectionType=0&productIds=1&projectIds=4&iterationIds=26&interval=NO_INTERVAL&startDate=&endDate=&userIds=#{user_id}"
    returned = HTTPoison.post!(@elephant_timesheet, data, headers).body
    |> Floki.find(".timesheet-header-ul .hoursum")
    |> hd
    {"li", _, [time]} = returned
    time
  end
end

