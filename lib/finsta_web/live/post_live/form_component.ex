defmodule FinstaWeb.PostLive.FormComponent do
  use FinstaWeb, :live_component

  alias Phoenix.LiveView.AsyncResult
  alias Finsta.Posts

  @upload_folder Application.compile_env(:finsta, :upload_folder)

  @impl true
  def mount(socket) do
    socket =
      socket
      |> assign(:hashtags_async, nil)
      |> allow_upload(:image, accept: ~w(.jpg .jpeg .png), max_entries: 1)

    {:ok, socket}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <.header>
        <%= @title %>
        <:subtitle>Use this form to manage post records in your database.</:subtitle>
      </.header>

      <.simple_form
        for={@form}
        id="post-form"
        phx-target={@myself}
        phx-change="validate"
        phx-submit="save"
      >
        <%= for image <- @uploads.image.entries do %>
          <figure>
            <.live_img_preview entry={image} />
          </figure>

          <progress value={image.progress} max="100"><%= image.progress %>%</progress>
        <% end %>

        <div :if={@hashtags_async}>
          <.async_result :let={hashtags} assign={@hashtags_async}>
            <:loading>Loading hashtags...</:loading>
            <:failed :let={_reason}>There was an error loading the hashtags</:failed>

            <%= hashtags %>
          </.async_result>
        </div>

        <.input field={@form[:caption]} phx-debounce="blur" type="text" label="Caption" />
        <.live_file_input :if={!@post.image_url} upload={@uploads.image} required />
        <:actions>
          <.button phx-disable-with="Saving...">Save Post</.button>
        </:actions>
      </.simple_form>
    </div>
    """
  end

  @impl true
  def update(%{post: post} = assigns, socket) do
    changeset = Posts.change_post(post)

    {:ok,
     socket
     |> assign(assigns)
     |> assign_form(changeset)}
  end

  @impl true
  def handle_event("validate", %{"post" => post_params}, socket) do
    changeset =
      socket.assigns.post
      |> Posts.change_post(post_params)
      |> Map.put(:action, :validate)

    socket =
      socket
      |> assign_hashtags(post_params)
      |> assign_form(changeset)

    {:noreply, socket}
  end

  def handle_event("save", %{"post" => post_params}, socket) do
    save_post(socket, socket.assigns.action, post_params)
  end

  def handle_async(:load_hashtags, {:ok, hashtags}, socket) do
    hashtags_async = socket.assigns.hashtags_async

    {:noreply,
     assign(
       socket,
       :hashtags_async,
       AsyncResult.ok(hashtags_async, hashtags)
     )}
  end

  defp assign_hashtags(socket, %{"caption" => caption}) do
    if String.trim(caption) == "" do
      socket
    else
      socket
      |> assign(:hashtags_async, AsyncResult.loading())
      |> start_async(:load_hashtags, fn ->
        Finsta.ChatGptApi.get_hashtags(caption)
      end)
    end
  end

  defp save_post(socket, :edit, post_params) do
    case Posts.update_post(socket.assigns.post, post_params) do
      {:ok, post} ->
        notify_parent({:saved, post})

        {:noreply,
         socket
         |> put_flash(:info, "Post updated successfully")
         |> push_patch(to: socket.assigns.patch)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign_form(socket, changeset)}
    end
  end

  defp save_post(socket, :new, post_params) do
    post_params = Map.put(post_params, "image_url", get_image_url(socket))

    case Posts.create_post(socket.assigns.current_user, post_params) do
      {:ok, post} ->
        notify_parent({:saved, post})

        {:noreply,
         socket
         |> put_flash(:info, "Post created successfully")
         |> push_patch(to: socket.assigns.patch)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign_form(socket, changeset)}
    end
  end

  defp assign_form(socket, %Ecto.Changeset{} = changeset) do
    assign(socket, :form, to_form(changeset))
  end

  defp notify_parent(msg), do: send(self(), {__MODULE__, msg})

  defp get_image_url(socket) do
    [image_url | _] =
      consume_uploaded_entries(socket, :image, fn meta, entry ->
        dest = Path.join(@upload_folder, entry.uuid)

        File.cp!(meta.path, dest)

        {:ok, ~p"/uploads/#{Path.basename(dest)}"}
      end)

    image_url
  end
end
