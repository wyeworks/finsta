defmodule Finsta.Repo.Migrations.AddImageUrlToPosts do
  use Ecto.Migration

  def change do
    alter table(:posts) do
      add :image_url, :string
    end
  end
end
