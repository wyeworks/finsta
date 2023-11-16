defmodule FinstaWeb.PostLive.Index do
  use FinstaWeb, :live_view

  alias Finsta.Posts
  alias Finsta.Posts.Post
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

    if connected?(socket) do
      :ok = Phoenix.PubSub.subscribe(Finsta.PubSub, "posts_topic")
    end

    {:ok, stream(socket, :posts, Posts.list_posts())}
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :edit, %{"id" => id}) do
    post = Posts.get_post!(id)

    if post.user_id == socket.assigns.current_user.id do
      socket
      |> assign(:page_title, "Edit Post")
      |> assign(:post, post)
    else
      socket
      |> put_flash(:error, "You are not authorized to edit this post")
      |> redirect(to: ~p"/posts")
    end
  end

  defp apply_action(socket, :new, _params) do
    socket
    |> assign(:page_title, "New Post")
    |> assign(:post, %Post{})
  end

  defp apply_action(socket, :index, _params) do
    socket
    |> assign(:page_title, "Listing Posts")
    |> assign(:post, nil)
  end

  @impl true
  def handle_info({FinstaWeb.PostLive.FormComponent, {:saved, post}}, socket) do
    {:noreply, stream_insert(socket, :posts, post)}
  end

  def handle_info({:insert, post}, socket) do
    {:noreply, stream_insert(socket, :posts, post, at: 0)}
  end

  def handle_info({:update, post}, socket) do
    {:noreply, stream_insert(socket, :posts, post, at: -1)}
  end

  def handle_info({:delete, post}, socket) do
    {:noreply, stream_delete(socket, :posts, post)}
  end

  @impl true
  def handle_event("delete", %{"id" => id}, socket) do
    post = Posts.get_post!(id)

    if post.user_id == socket.assigns.current_user.id do
      {:ok, _} = Posts.delete_post(post)

      {:noreply, stream_delete(socket, :posts, post)}
    else
      socket
      |> put_flash(:error, "You are not authorized to delete this post")
      |> redirect(to: ~p"/posts")
    end
  end

  @impl true
  def handle_event("toggle_like", %{"id" => post_id}, socket) do
    Posts.toggle_like(post_id, socket.assigns.current_user.id)
    {:noreply, socket}
  end

  attr :current_user_id, :integer
  attr :post_likes, :list

  def like(assigns) do
    ~H"""
    <div class="flex w-10 space-x-2 justify-center items-center mr-2">
      <.icon
        :if={@current_user_id not in Enum.map(@post_likes, fn like -> like.user_id end)}
        name="hero-heart"
        class="h-4 w-4"
      />
      <.icon
        :if={@current_user_id in Enum.map(@post_likes, fn like -> like.user_id end)}
        name="hero-heart-solid"
        class="h-4 w-4 bg-red-600"
      />
      <span><%= Enum.count(@post_likes) %></span>
    </div>
    """
  end
end
