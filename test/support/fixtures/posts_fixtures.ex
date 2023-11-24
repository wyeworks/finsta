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

    {:ok, post} =
      attrs
      |> Enum.into(%{
        caption: "some caption",
        user_id: user.id,
        image_url: "image.png"
      })
      |> Finsta.Posts.create_post()

    post
  end
end
