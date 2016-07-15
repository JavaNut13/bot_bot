defmodule BotBot.Elephant do
  alias BotBot.Store
  @url Application.get_env(:bot_bot, :url)

  @endpoint Application.get_env(:bot_bot, :endpoint)
  @project Application.get_env(:bot_bot, :project_id)
  @token Application.get_env(:bot_bot, :gitlab_token)
  
  @gitlab_url "#{@endpoint}/api/v3/projects/#{@project}/merge_requests?private_token=#{@token}&state=opened"

  @doc "Post a message. Used by quantum"
  def post_message do
    attachments = HTTPoison.get!(@gitlab_url).body
    |> Poison.decode!
    |> Enum.map(fn mr ->
      mr_to_attachment mr
    end)
    post %{attachments: attachments}
  end

  @doc "Post a message to #general as Elixphant"
  def post(data = %{}) do
    body = Poison.encode! data
    HTTPoison.post! @url, body
  end

  def post(message) do
    post(%{text: message})
  end

  defp mr_to_attachment(mr) do
    text = text_for mr
    %{
      fallback: text,
      color: color(mr),
      text: text
    }
  end

  defp color(mr) do
    net_votes = mr["upvotes"] - mr["downvotes"]
    cond do
      mr["work_in_progress"] ->
       "#5E5E5E"
      net_votes >= 2 ->
        "green"
      net_votes == 1 ->
        "#56BADB"
      true ->
        "#E8773A"
    end
  end

  defp text_for(mr = %{"iid" => mr_number}) do
    case Store.get_users(mr_number) do
      nil ->
        "No pair for #{link_for mr_number}: #{description_for mr}"
      users ->
        "#{join_users(users)} need to review #{link_for mr_number}: #{description_for mr}"
    end
  end

  defp description_for(mr) do
    mr["title"] <> " by @" <> mr["author"]["username"]
  end

  defp join_users(users) do
    users
    |> Stream.map(fn user -> "@#{user}" end)
    |> Enum.join(", ")
  end

  @doc "Get a slack-formatted link for a MR number"
  def link_for(mr_number) do
    "<#{url_for mr_number}|MR #{mr_number}>"
  end

  defp url_for(mr_number) do
    "https://eng-git.canterbury.ac.nz/SENG302-2016/team-1/merge_requests/#{mr_number}"
  end
end

