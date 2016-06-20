defmodule ElephantBot do
  @url Application.get_env(:elephant_bot, :url)

  @endpoint Application.get_env(:elephant_bot, :endpoint)
  @project Application.get_env(:elephant_bot, :project_id)
  @token Application.get_env(:elephant_bot, :gitlab_token)
  
  @gitlab_url "#{@endpoint}/api/v3/projects/#{@project}/merge_requests?private_token=#{@token}&state=opened"

  def start do
    HTTPoison.start
  end

  @doc "Wait for a certain hour (24 hour) and then send a message to the waiting process to post the update"
  def wait_and_send_at(time) do
    if current_hour == time do
      spawn(fn ->
        post get_message
      end)
      :timer.sleep 1000 * 60 * 60 # So we don't post twice in one hour
    end
    :timer.sleep 1000 * 60 * 10 # Wait for 10 minutes
    wait_and_send_at time
  end

  @doc "Subscribe to a redis channel that will notify when to send an update"
  def subscribe(chan_name) do
    {:ok, client_sub} = Exredis.Sub.start_link
    Exredis.Sub.subscribe client_sub, "foo", fn
      {:message, ^chan_name, _, _} ->
        spawn(fn -> post get_message end)
      msg -> IO.inspect msg
    end
  end

  @doc "Create a message from the open merge requests"
  def get_message do
    redis = Store.get_client
    HTTPoison.get!(@gitlab_url).body
    |> Poison.decode!
    |> Stream.filter(fn mr ->
      !mr["work_in_progress"]
    end)
    |> Stream.map(fn %{"iid" => mr} ->
      case Store.get_users(redis, mr) do
        nil -> "No pair for #{link_for mr}"
        users ->
          usr_str = join_users users
          "#{usr_str} need to review #{link_for mr}"
      end
    end)
    |> Enum.join("\n")
  end

  defp join_users(users) do
    users
    |> Stream.map(fn user -> "@#{user}" end)
    |> Enum.join(", ")
  end

  defp post(message) do
    body = %{text: message}
    |> Poison.encode!
    HTTPoison.post! @url, body
  end

  defp current_hour do
    {_, {hour, _, _}} = :calendar.local_time()
    hour
  end

  defp link_for(mr_number) do
    "<#{url_for mr_number}|MR #{mr_number}>"
  end

  defp url_for(mr_number) do
    "https://eng-git.canterbury.ac.nz/SENG302-2016/team-1/merge_requests/#{mr_number}"
  end
end

