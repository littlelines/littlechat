defmodule Littlechat.Repo.Migrations.AddActiveCallBoolToRooms do
  use Ecto.Migration

  def change do
    alter table("rooms") do
      add :active_call, :boolean, default: false
    end
  end
end
