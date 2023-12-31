defmodule FinstaWeb.PostLiveTest do
  use FinstaWeb.ConnCase

  import Phoenix.LiveViewTest
  import Finsta.PostsFixtures
  import Finsta.AccountsFixtures

  alias Finsta.Posts.Post

  @create_attrs %{caption: "some caption"}
  @update_attrs %{caption: "some updated caption"}
  @invalid_attrs %{caption: nil}

  defp authenticate_user(%{conn: conn}) do
    logged_out_conn = conn

    user = user_fixture()
    conn = log_in_user(conn, user)

    %{conn: conn, logged_out_conn: logged_out_conn, user: user}
  end

  defp create_post(%{user: user}) do
    post = post_fixture(%{user_id: user.id})

    %{post: post}
  end

  describe "Index" do
    setup [:authenticate_user, :create_post]

    test "lists all posts", %{conn: conn, post: post} do
      {:ok, _index_live, html} = live(conn, ~p"/posts")

      assert html =~ "Listing Posts"
      assert html =~ post.caption
    end

    test "saves new post", %{conn: conn} do
      {:ok, index_live, _html} = live(conn, ~p"/posts")

      assert index_live |> element("a", "New Post") |> render_click() =~
               "New Post"

      assert_patch(index_live, ~p"/posts/new")

      assert index_live
             |> form("#post-form", post: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      image =
        file_input(index_live, "#post-form", :image, [
          %{
            last_modified: 1_594_171_879_000,
            name: "phoenix.png",
            content: File.read!("test/support/fixtures/phoenix.png"),
            type: "image/png"
          }
        ])

      render_upload(image, "phoenix.png")

      assert index_live
             |> form("#post-form", post: @create_attrs)
             |> render_submit()

      assert_patch(index_live, ~p"/posts")

      html = render(index_live)
      assert html =~ "Post created successfully"
      assert html =~ "some caption"
    end

    test "updates post in listing", %{conn: conn, post: post} do
      {:ok, index_live, _html} = live(conn, ~p"/posts")

      assert index_live |> element("#posts-#{post.id} a", "Edit") |> render_click() =~
               "Edit Post"

      assert_patch(index_live, ~p"/posts/#{post}/edit")

      assert index_live
             |> form("#post-form", post: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      assert index_live
             |> form("#post-form", post: @update_attrs)
             |> render_submit()

      assert_patch(index_live, ~p"/posts")

      html = render(index_live)
      assert html =~ "Post updated successfully"
      assert html =~ "some updated caption"
    end

    test "deletes post in listing", %{conn: conn, post: post} do
      {:ok, index_live, _html} = live(conn, ~p"/posts")

      assert index_live |> element("#posts-#{post.id} a", "Delete") |> render_click()
      refute has_element?(index_live, "#posts-#{post.id}")
    end

    test "doesn't show edit button in listing when post doesn't belong to the user", %{conn: conn} do
      post = post_fixture()

      {:ok, index_live, _html} = live(conn, ~p"/posts")

      refute index_live |> has_element?("#posts-#{post.id} a", "Edit")
    end

    test "doesn't show delete button in listing when post doesn't belong to the user", %{
      conn: conn
    } do
      post = post_fixture()

      {:ok, index_live, _html} = live(conn, ~p"/posts")

      refute index_live |> has_element?("#posts-#{post.id} a", "Delete")
    end

    test "likes posts in listing", %{conn: conn, post: post} do
      {:ok, index_live, _html} = live(conn, ~p"/posts")

      like_button = index_live |> element("#posts-#{post.id} button", "0")

      assert like_button |> render() =~ "hero-heart "
      assert like_button |> render_click() =~ "hero-heart-solid "

      like_button = index_live |> element("#posts-#{post.id} button", "1")

      assert like_button |> render() =~ "hero-heart-solid "
      assert like_button |> render_click() =~ "hero-heart "
    end

    test "inserts post in page when :created event is received", %{conn: conn, post: post} do
      {:ok, index_live, _html} = live(conn, ~p"/posts")

      assert render(index_live) =~ post.caption

      new_post = %Post{
        id: post.id + 1,
        caption: "another caption",
        image_url: "another_image.png"
      }

      send(index_live.pid, {:insert, new_post})

      assert render(index_live) =~ ~r/#{post.caption}.*#{new_post.caption}/s
    end

    test "updates post in page when :update event is received", %{conn: conn, post: post} do
      {:ok, index_live, _html} = live(conn, ~p"/posts")

      assert render(index_live) =~ post.caption

      new_post = %Post{post | caption: "new_caption"}

      send(index_live.pid, {:update, new_post})

      assert render(index_live) =~ new_post.caption
      refute render(index_live) =~ post.caption
    end

    test "removes post from page when :delete event is received", %{conn: conn, post: post} do
      new_post = post_fixture(%{caption: "another caption"})

      {:ok, index_live, _html} = live(conn, ~p"/posts")

      assert render(index_live) =~ ~r/#{new_post.caption}.*#{post.caption}/s

      send(index_live.pid, {:delete, new_post})

      assert render(index_live) =~ post.caption
      refute render(index_live) =~ new_post.caption
    end
  end

  describe "Show" do
    setup [:authenticate_user, :create_post]

    test "non authenticated user can't see the page", %{logged_out_conn: conn} do
      assert {:error, redirect} = live(conn, ~p"/posts")
      assert {:redirect, %{to: path, flash: flash}} = redirect
      assert path == ~p"/users/log_in"
      assert %{"error" => "You must log in to access this page."} = flash
    end

    test "displays post", %{conn: conn, post: post} do
      {:ok, _show_live, html} = live(conn, ~p"/posts/#{post}")

      assert html =~ "Show Post"
      assert html =~ post.caption
    end

    test "updates post within modal", %{conn: conn, post: post} do
      {:ok, show_live, _html} = live(conn, ~p"/posts/#{post}")

      assert show_live |> element("a", "Edit") |> render_click() =~
               "Edit Post"

      assert_patch(show_live, ~p"/posts/#{post}/show/edit")

      assert show_live
             |> form("#post-form", post: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      assert show_live
             |> form("#post-form", post: @update_attrs)
             |> render_submit()

      assert_patch(show_live, ~p"/posts/#{post}")

      html = render(show_live)
      assert html =~ "Post updated successfully"
      assert html =~ "some updated caption"
    end

    test "doesn't show edit when post doesn't belong to the user", %{conn: conn} do
      post = post_fixture()

      {:ok, show_live, _html} = live(conn, ~p"/posts/#{post}")

      refute show_live |> has_element?("a", "Edit")
    end

    test "returns 404 when visiting /edit route and post doesn't belong to the user", %{
      conn: conn
    } do
      post = post_fixture()

      assert_raise Ecto.NoResultsError, fn -> live(conn, ~p"/posts/#{post}/edit") end
    end

    test "likes posts", %{conn: conn, post: post} do
      {:ok, show_live, _html} = live(conn, ~p"/posts/#{post}")

      like_button = show_live |> element("button", "0")

      assert like_button |> render() =~ "hero-heart "
      assert like_button |> render_click() =~ "hero-heart-solid "

      like_button = show_live |> element("button", "1")

      assert like_button |> render() =~ "hero-heart-solid "
      assert like_button |> render_click() =~ "hero-heart "
    end

    test "updates post in page when :update event is received", %{conn: conn, post: post} do
      {:ok, show_live, _html} = live(conn, ~p"/posts/#{post}")

      assert render(show_live) =~ post.caption

      new_post = %Post{post | caption: "new_caption"}

      send(show_live.pid, {:update, new_post})

      assert render(show_live) =~ new_post.caption
      refute render(show_live) =~ post.caption
    end

    test "redirects to index when :delete event is received", %{conn: conn, post: post} do
      {:ok, show_live, _html} = live(conn, ~p"/posts/#{post}")

      assert render(show_live) =~ post.caption

      send(show_live.pid, {:delete, post})

      flash = assert_redirect(show_live, "/posts")
      assert flash["error"] == "Post was deleted."
    end
  end
end
