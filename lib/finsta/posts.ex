defmodule Finsta.Posts do
  @moduledoc """
  The Posts context.
  """

  import Ecto.Query, warn: false
  alias Finsta.Repo

  alias Finsta.Posts.Post

  @doc """
  Returns the list of posts.

  ## Examples

      iex> list_posts()
      [%Post{}, ...]

  """
  def list_posts do
    Post |> reverse_order() |> Repo.all()
  end

  @doc """
  Gets a single post.

  Raises `Ecto.NoResultsError` if the Post does not exist.

  ## Examples

      iex> get_post!(123)
      %Post{}

      iex> get_post!(456)
      ** (Ecto.NoResultsError)

  """
  def get_post!(id), do: Repo.get!(Post, id)

  @doc """
  Creates a post.

  ## Examples

      iex> create_post(user, %{field: value})
      {:ok, %Post{}}

      iex> create_post(user, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_post(user, attrs) do
    %Post{}
    |> Post.changeset(attrs)
    |> Ecto.Changeset.put_assoc(:user, user)
    |> Repo.insert()
    |> tap(&broadcast_post(&1, :insert))
  end

  @doc """
  Updates a post.

  ## Examples

      iex> update_post(post, %{field: new_value})
      {:ok, %Post{}}

      iex> update_post(post, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_post(%Post{} = post, attrs) do
    post
    |> Post.changeset(attrs)
    |> Repo.update()
    |> tap(&broadcast_post(&1, :update))
  end

  @doc """
  Deletes a post.

  ## Examples

      iex> delete_post(post)
      {:ok, %Post{}}

      iex> delete_post(post)
      {:error, %Ecto.Changeset{}}

  """
  def delete_post(%Post{} = post) do
    post
    |> Repo.delete()
    |> tap(&broadcast_post(&1, :delete))
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking post changes.

  ## Examples

      iex> change_post(post)
      %Ecto.Changeset{data: %Post{}}

  """
  def change_post(%Post{} = post, attrs \\ %{}) do
    Post.changeset(post, attrs)
  end

  defp broadcast_post({:error, _changeset}, _message_type), do: nil

  defp broadcast_post({:ok, post}, message_type) when message_type in [:insert, :update, :delete],
    do: Phoenix.PubSub.broadcast(Finsta.PubSub, "posts_topic", {message_type, post})
end
