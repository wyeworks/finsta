defmodule Finsta.PostsFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `Finsta.Posts` context.
  """

  import Finsta.AccountsFixtures

  @doc """
  Generate a post.
  """
  def post_fixture(attrs \\ %{}) do
    user = user_fixture()
    create_post(user, attrs)
  end

  def post_with_user_fixture(user, attrs \\ %{}) do
    create_post(user, attrs)
  end

  defp create_post(user, attrs) do
    attrs =
      attrs
      |> Enum.into(%{
        caption: "some caption",
        image_url: "image.png"
      })

    {:ok, post} = Finsta.Posts.create_post(user, attrs)

    post
  end
end
