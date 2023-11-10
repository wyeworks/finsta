defmodule Finsta.Posts.Post do
  use Ecto.Schema
  import Ecto.Changeset

  schema "posts" do
    field :caption, :string
    belongs_to :user, Finsta.Accounts.User

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(post \\ %__MODULE__{}, attrs) do
    post
    |> cast(attrs, [:caption])
    |> validate_required([:caption])
  end
end
