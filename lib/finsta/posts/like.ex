defmodule Finsta.Posts.Like do
  use Ecto.Schema
  import Ecto.Changeset

  schema "likes" do
    belongs_to :post, Finsta.Posts.Post
    belongs_to :user, Finsta.Accounts.User

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(like \\ %__MODULE__{}, attrs) do
    like
    |> cast(attrs, [:post_id, :user_id])
    |> validate_required([:post_id, :user_id])
  end
end
