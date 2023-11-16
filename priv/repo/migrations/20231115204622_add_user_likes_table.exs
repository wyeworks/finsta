defmodule Finsta.Repo.Migrations.AddUserLikesTable do
  use Ecto.Migration

  def change do
    create table(:likes) do
      add :user_id, references(:users, on_delete: :nothing)
      add :post_id, references(:posts, on_delete: :delete_all)
      timestamps(type: :utc_datetime)
    end

    create unique_index(:likes, [:user_id, :post_id])
  end
end
