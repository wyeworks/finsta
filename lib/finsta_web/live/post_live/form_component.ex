defmodule FinstaWeb.PostLive.FormComponent do
  use FinstaWeb, :live_component

  alias Finsta.Posts

  @upload_folder Application.compile_env(:finsta, :upload_folder)

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

        <.input field={@form[:caption]} type="text" label="Caption" />
        <.live_file_input :if={!@post.image_url} upload={@uploads.image} required />
        <:actions>
          <.button phx-disable-with="Saving...">Save Post</.button>
        </:actions>
      </.simple_form>
    </div>
    """
  end

  @impl true
  def mount(socket) do
    {:ok, allow_upload(socket, :image, accept: ~w(.jpg .jpeg .png), max_entries: 1)}
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

    {:noreply, assign_form(socket, changeset)}
  end

  def handle_event("save", %{"post" => post_params}, socket) do
    save_post(socket, socket.assigns.action, post_params)
  end

  defp save_post(socket, :edit, post_params) do
    case Posts.update_post(socket.assigns.post, post_params) do
      {:ok, _post} ->
        {:noreply,
         socket
         |> put_flash(:info, "Post updated successfully")
         |> push_patch(to: socket.assigns.patch)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign_form(socket, changeset)}
    end
  end

  defp save_post(socket, :new, post_params) do
    user_id = socket.assigns.user_id

    post_params =
      post_params
      |> Map.put("user_id", user_id)
      |> Map.put("image_url", get_image_url(socket))

    case Posts.create_post(post_params) do
      {:ok, _post} ->
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
