defmodule FinstaWeb.PostLive.LikeComponent do
  use FinstaWeb, :live_component

  alias Finsta.Posts

  @impl true
  def render(%{post_likes: post_likes} = assigns) when not is_list(post_likes) do
    assigns
    |> Map.put(:post_likes, [])
    |> render()
  end

  def render(assigns) do
    ~H"""
    <button phx-click="toggle_like" phx-value-id={@id} phx-target={@myself}>
      <div class="flex w-10 space-x-2 justify-center items-center mr-2">
        <.icon
          :if={@current_user.id not in Enum.map(@post_likes, fn like -> like.user_id end)}
          name="hero-heart"
          class="h-4 w-4"
        />
        <.icon
          :if={@current_user.id in Enum.map(@post_likes, fn like -> like.user_id end)}
          name="hero-heart-solid"
          class="h-4 w-4 bg-red-600"
        />
        <span><%= Enum.count(@post_likes) %></span>
      </div>
    </button>
    """
  end

  @impl true
  def handle_event("toggle_like", %{"id" => post_id}, socket) do
    {:ok, _like} = Posts.toggle_like(post_id, socket.assigns.current_user.id)
    %{likes: likes} = Posts.get_post!(post_id)

    {:noreply, assign(socket, post_likes: likes)}
  end
end
