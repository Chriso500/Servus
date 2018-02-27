defmodule Servus.Repo.Migrations.PlayerUserdata do
  use Ecto.Migration

  def change do
      create table("playerUserdata") do
      add(:player_id, references("playerLogin"))
      add(:mainpicture, :string)
      timestamps()
    end
    create unique_index("playerUserdata", [:player_id])
  end
end
