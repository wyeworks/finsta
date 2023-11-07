defmodule FinstaWeb.PostLive.Show do
  use FinstaWeb, :live_view

  alias Finsta.Posts
  alias Finsta.Accounts

  @impl true
  def mount(_params, %{"user_token" => user_token} = _session, socket) do
    socket = assign(socket, current_user: Accounts.get_user_by_session_token(user_token))
    socket =
      if socket.assigns.current_user.id do
        socket
      else
        redirect(socket, to: "/login")
      end
    {:ok, stream(socket, :posts, Posts.list_posts())}
  end

  @impl true
  def handle_params(%{"id" => id}, _, socket) do
    {:noreply,
     socket
     |> assign(:page_title, page_title(socket.assigns.live_action))
     |> assign(:post, Posts.get_post!(id))}
  end

  defp page_title(:show), do: "Show Post"
  defp page_title(:edit), do: "Edit Post"
end
