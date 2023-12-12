defmodule FinstaWeb.PostLive.Index do
  use FinstaWeb, :live_view

  alias Finsta.Posts
  alias Finsta.Posts.Post

  @impl true
  def mount(_params, _session, socket) do
    {:ok, stream(socket, :posts, Posts.list_posts())}
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :edit, %{"id" => post_id}) do
    %{id: user_id} = socket.assigns.current_user

    socket
    |> assign(:page_title, "Edit Post")
    |> assign(:post, Posts.get_user_post!(user_id, post_id))
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

  @impl true
  def handle_event("delete", %{"id" => post_id}, socket) do
    %{id: user_id} = socket.assigns.current_user
    post = Posts.get_user_post!(user_id, post_id)

    {:ok, _} = Posts.delete_post(post)

    {:noreply, stream_delete(socket, :posts, post)}
  end
end
