defmodule BotBot.Elephant do
  alias BotBot.Store
  @url Application.get_env(:bot_bot, :url)

  @endpoint Application.get_env(:bot_bot, :endpoint)
  @project Application.get_env(:bot_bot, :project_id)
  @token Application.get_env(:bot_bot, :gitlab_token)
  
  @gitlab_url "#{@endpoint}/api/v3/projects/#{@project}/merge_requests?private_token=#{@token}&state=opened"

  @doc "Post a message. Used by quantum"
  def post_message do
    post get_message
  end

  @doc "Create a message from the open merge requests"
  def get_message do
    # TODO this isn't going to work :(
    store = Process.whereis :user_store
    HTTPoison.get!(@gitlab_url).body
    |> Poison.decode!
    |> Stream.filter(fn mr ->
      !mr["work_in_progress"]
    end)
    |> Stream.map(fn %{"iid" => mr} ->
      case Store.get_users(store, mr) do
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

  @doc "Get a slack-formatted link for a MR number"
  def link_for(mr_number) do
    "<#{url_for mr_number}|MR #{mr_number}>"
  end

  defp url_for(mr_number) do
    "https://eng-git.canterbury.ac.nz/SENG302-2016/team-1/merge_requests/#{mr_number}"
  end
end

