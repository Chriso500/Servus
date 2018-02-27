defmodule Servus.PlayerUserdata do
  use Ecto.Schema
  import Ecto.Changeset

  schema "playerUserdata" do
    belongs_to :player, Servus.PlayerLogin
    field(:mainpicture, :string)
    timestamps()
  end

  def add_PlayerUserdata(playerUserdata, params \\ %{}) do
    playerUserdata
      |> cast(params, [:player_id, :mainpicture])
      |> foreign_key_constraint(:player)
      |> cast_assoc(:player)
  end
end