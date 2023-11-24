defmodule Finsta.PostsTest do
  use Finsta.DataCase

  alias Finsta.Posts

  describe "posts" do
    alias Finsta.Posts.Post

    import Finsta.PostsFixtures
    import Finsta.AccountsFixtures

    @invalid_attrs %{caption: nil}

    test "list_posts/0 returns all posts" do
      post = post_fixture()
      assert Posts.list_posts() == [post]
    end

    test "get_post!/1 returns the post with given id" do
      post = post_fixture()
      assert Posts.get_post!(post.id) == post
    end

    test "get_user_post!/2 returns the post with given id if the post belongs to the user" do
      user = user_fixture()
      post = post_fixture(%{user_id: user.id})

      result = Posts.get_user_post!(user.id, post.id)

      assert result.caption == post.caption
      assert result.user_id == post.user_id
    end

    test "get_user_post!/2 raises NoResultError when the post with given id doesn't belong to the user " do
      user = user_fixture()
      post = post_fixture()

      assert_raise Ecto.NoResultsError, fn -> Posts.get_user_post!(user.id, post.id) end
    end

    test "create_post/1 with valid data creates a post" do
      user = user_fixture()
      valid_attrs = %{caption: "some caption", user_id: user.id, image_url: "image.png"}

      assert {:ok, %Post{} = post} = Posts.create_post(valid_attrs)
      assert post.caption == "some caption"
    end

    test "create_post/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Posts.create_post(@invalid_attrs)
    end

    test "update_post/2 with valid data updates the post" do
      post = post_fixture()
      update_attrs = %{caption: "some updated caption"}

      assert {:ok, %Post{} = post} = Posts.update_post(post, update_attrs)
      assert post.caption == "some updated caption"
    end

    test "update_post/2 with invalid data returns error changeset" do
      post = post_fixture()
      assert {:error, %Ecto.Changeset{}} = Posts.update_post(post, @invalid_attrs)
      assert post == Posts.get_post!(post.id)
    end

    test "delete_post/1 deletes the post" do
      post = post_fixture()
      assert {:ok, %Post{}} = Posts.delete_post(post)
      assert_raise Ecto.NoResultsError, fn -> Posts.get_post!(post.id) end
    end

    test "change_post/1 returns a post changeset" do
      post = post_fixture()
      assert %Ecto.Changeset{} = Posts.change_post(post)
    end
  end
end
