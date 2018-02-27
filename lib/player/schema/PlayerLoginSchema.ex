defmodule Servus.PlayerLogin do
  use Ecto.Schema
  import Ecto.Changeset

  schema "playerLogin" do
    field(:nickname, :string)
    field(:internalPlayerKey, :integer)
    field(:email, :string)
    field(:passwortMD5Hash, :string)
    field(:facebook_id, :string)
    field(:facebook_token, :string)
    field(:facebook_token_expires, :integer)
    field(:confirmed, :boolean, default: false)
    timestamps()
  end

  def add_Player_Only(playerLogin, params \\ %{}) do
    playerLogin
      |> cast(params, [:nickname, :internalPlayerKey])
      |> unique_constraint(:internalPlayerKey)
  end

  def add_Player_Self(playerLogin, params \\ %{}) do
    playerLogin
      |> cast(params, [:nickname, :email, :passwortMD5Hash])
      |> unique_constraint(:email)
  end

  def add_Player_FB(playerLogin, params \\ %{}) do
    playerLogin
      |> cast(params, [:email, :facebook_id, :nickname, :facebook_token, :facebook_token_expires])
      |> unique_constraint(:facebook_id)
      |> unique_constraint(:email)
  end
end