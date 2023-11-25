defmodule FinstaWeb.PostLive.Show do
  use FinstaWeb, :live_view

  alias Finsta.Posts

  @impl true
  def mount(_params, _session, socket) do
    if connected?(socket) do
      :ok = Phoenix.PubSub.subscribe(Finsta.PubSub, "posts_topic")
    end

    {:ok, socket}
  end

  @impl true
  def handle_params(%{"id" => id}, _, socket) do
    {:noreply,
     socket
     |> assign(:page_title, page_title(socket.assigns.live_action))
     |> assign(:post, Posts.get_post!(id))}
  end

  @impl true
  def handle_info({:update, post}, socket) do
    {:noreply, assign(socket, :post, post)}
  end

  def handle_info({:delete, _post}, socket) do
    {:noreply,
     socket
     |> put_flash(:error, "Post was deleted.")
     |> push_navigate(to: ~p"/posts")}
  end

  def handle_info(_, socket) do
    {:noreply, socket}
  end

  defp page_title(:show), do: "Show Post"
  defp page_title(:edit), do: "Edit Post"
end
