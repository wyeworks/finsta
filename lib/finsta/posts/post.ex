defmodule Finsta.Posts.Post do
  use Ecto.Schema
  import Ecto.Changeset

  schema "posts" do
    field :caption, :string
    field :user_id, :id
    field :image_url, :string

    has_many :likes, Finsta.Posts.Like, on_delete: :delete_all

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(post, attrs) do
    post
    |> cast(attrs, [:caption, :user_id, :image_url])
    |> validate_required([:caption, :user_id, :image_url])
  end
end
