defmodule Finsta.Posts.Post do
  use Ecto.Schema
  import Ecto.Changeset

  schema "posts" do
    field :caption, :string
    field :image_url, :string
    belongs_to :user, Finsta.Accounts.User

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(post \\ %__MODULE__{}, attrs) do
    post
    |> cast(attrs, [:caption, :image_url])
    |> validate_required([:caption, :image_url])
  end
end
