defmodule Finsta.Posts.Post do
  use Ecto.Schema
  import Ecto.Changeset

  @required_fields ~w(
    caption
    user_id
  )a

  @allowed_fields ~w()a ++ @required_fields

  schema "posts" do
    field :caption, :string
    field :user_id, :id

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(post \\ %__MODULE__{}, attrs) do
    post
    |> cast(attrs, @allowed_fields)
    |> validate_required(@required_fields)
  end
end
