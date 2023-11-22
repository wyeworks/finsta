defmodule FinstaWeb.PostLiveTest do
  use FinstaWeb.ConnCase

  import Phoenix.LiveViewTest
  import Finsta.PostsFixtures
  import Finsta.AccountsFixtures

  @create_attrs %{caption: "some caption"}
  @update_attrs %{caption: "some updated caption"}
  @invalid_attrs %{caption: nil}

  defp create_post(user \\ nil) do
    post_with_user_fixture(user)
  end

  setup %{conn: conn} do
    logged_out_conn = conn
    user = user_fixture()
    conn = log_in_user(conn, user)
    {:ok, %{conn: conn, logged_out_conn: logged_out_conn, user: user}}
  end

  describe "Index" do
    setup %{conn: conn, user: user} do
      {:ok, %{post: create_post(user), conn: conn}}
    end

    test "non authenticated user can't see the page", %{logged_out_conn: conn} do
      assert {:error, redirect} = live(conn, ~p"/posts")
      assert {:redirect, %{to: path, flash: flash}} = redirect
      assert path == ~p"/users/log_in"
      assert %{"error" => "You must log in to access this page."} = flash
    end

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

    test "updates post in listing when post belongs to user", %{conn: conn, post: post} do
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

    test "doesn't show edit button in listing when post doesn't belong to the user", %{conn: conn} do
      post = create_post()

      {:ok, index_live, _html} = live(conn, ~p"/posts")

      refute index_live |> has_element?("#posts-#{post.id} a", "Edit")
    end

    test "deletes post in listing when post belongs to the user", %{conn: conn, post: post} do
      {:ok, index_live, _html} = live(conn, ~p"/posts")

      assert index_live |> element("#posts-#{post.id} a", "Delete") |> render_click()
      refute has_element?(index_live, "#posts-#{post.id}")
    end

    test "doesn't show delete button in listing when post doesn't belong to the user", %{
      conn: conn
    } do
      post = create_post()

      {:ok, index_live, _html} = live(conn, ~p"/posts")

      refute index_live |> has_element?("#posts-#{post.id} a", "Delete")
    end
  end

  describe "Show" do
    setup %{conn: conn, user: user} do
      {:ok, %{post: create_post(user), conn: conn}}
    end

    test "displays post", %{conn: conn, post: post} do
      {:ok, _show_live, html} = live(conn, ~p"/posts/#{post}")

      assert html =~ "Show Post"
      assert html =~ post.caption
    end

    test "updates post within modal when post belongs to the user", %{conn: conn, post: post} do
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

    test "doesn't show edit button when post doesn't belong to the user", %{conn: conn} do
      post = create_post()

      {:ok, show_live, _html} = live(conn, ~p"/posts/#{post}")

      refute show_live |> has_element?("a", "Edit")
    end

    test "returns 404 when visiting /edit route and post doesn't belong to the user", %{
      conn: conn
    } do
      post = create_post()

      assert_raise Ecto.NoResultsError, fn -> live(conn, ~p"/posts/#{post}/edit") end
    end
  end
end
