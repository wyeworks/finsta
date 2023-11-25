defmodule Finsta.PostsTest do
  use Finsta.DataCase

  alias Finsta.Posts

  describe "posts" do
    alias Finsta.Posts.{Like, Post}

    import Finsta.PostsFixtures
    import Finsta.AccountsFixtures

    @invalid_attrs %{caption: nil}

    test "list_posts/0 returns all posts" do
      first_post = post_fixture()
      last_post = post_fixture()

      [first_result, last_result] = Posts.list_posts()

      assert first_result.caption == last_post.caption
      assert first_result.user_id == last_post.user_id
      assert first_result.image_url == last_post.image_url
      assert first_result.likes == []

      assert last_result.id == first_post.id
    end

    test "get_post!/1 returns the post with given id" do
      post = post_fixture()
      result = Posts.get_post!(post.id)

      assert post.caption == result.caption
      assert post.user_id == result.user_id
      assert post.image_url == result.image_url
      assert [] == result.likes
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

      post = Posts.get_post!(post.id)

      assert post.caption == "some caption"
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

    test "toggle_like/2 adds a like to the post when user hasn't liked it yet" do
      post = post_fixture()
      user = user_fixture()

      {:ok, %Like{} = like} = Posts.toggle_like(post.id, user.id)

      assert like.post_id == post.id
      assert like.user_id == user.id
    end

    test "toggle_like/2 removes a like to the post when user has liked it already" do
      post = post_fixture()
      user_1 = user_fixture()
      user_2 = user_fixture()

      {:ok, %Like{} = like_1} = Posts.toggle_like(post.id, user_1.id)
      {:ok, %Like{} = like_2} = Posts.toggle_like(post.id, user_2.id)
      post = Posts.get_post!(post.id)

      assert post.likes == [like_1, like_2]

      Posts.toggle_like(post.id, user_1.id)
      post = Posts.get_post!(post.id)

      assert post.likes == [like_2]

      Posts.toggle_like(post.id, user_2.id)
      post = Posts.get_post!(post.id)

      assert post.likes == []
    end
  end
end
