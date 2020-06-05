defmodule Littlechat.Repo.Migrations.CreateRooms do
  use Ecto.Migration

  def change do
    create table("rooms") do
      add :slug, :string
      add :title, :string

      timestamps()
    end

    create unique_index(:rooms, :slug)
  end
end
