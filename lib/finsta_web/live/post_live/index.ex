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
    socket
    |> assign(:page_title, "Edit Post")
    |> assign(:post, Posts.get_post!(id))
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

  def handle_info({:new, post}, socket) do
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
    {:ok, _} = Posts.delete_post(post)

    {:noreply, stream_delete(socket, :posts, post)}
  end
end
