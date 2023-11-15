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
