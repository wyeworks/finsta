defmodule Finsta.PostsFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `Finsta.Posts` context.
  """

  @doc """
  Generate a post.
  """
  def post_fixture(attrs \\ %{}) do
    {:ok, post} =
      attrs
      |> Enum.into(%{
        caption: "some caption"
      })
      |> Finsta.Posts.create_post()

    post
  end
end
