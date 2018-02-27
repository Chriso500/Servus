defmodule Player_Self do
  @moduledoc """
  
  """  
  alias Servus.Serverutils
  alias Servus.{Repo, PlayerLogin}
  use Servus.Module 
  require Logger
  import Ecto.Query, only: [from: 2]

  register ["player","self"]
   @doc """
   Create SQL DB Connection
   Create Table Players @ Startup if needed
   Adds Fiels to Table if needed
  """
  def startup() do
    Logger.info "Player_self module registered"
  end
  @doc """
   Register new Client with email and password and nickname 
   Returns id for Login
  """

  handle ["register"], %{nick: _, email: _, password: _ } = args , client, state do
    newPlayer = PlayerLogin.add_Player_Self(%PlayerLogin{},%{nickname: args.nick, email: args.email, passwortMD5Hash: Serverutils.get_md5_hex(args.password)})
    response = Repo.insert(newPlayer)
    Logger.info "DB Response for register insert #{inspect response}"
    case response do 
    {:ok, responsePL} ->
        Logger.info "Create new player #{args.nick} with id #{responsePL.id} and mail #{args.email}"
        %{result_code: :ok, result: %{id: responsePL.id}}
    {:error, responsePL} ->
        Logger.info "Error Create new player #{args.nick} and mail #{args.email}"
        %{result_code: :error, result: responsePL.errors}
    _->
      %{result_code: :error, result: nil}
    end
  end

    @doc """
    Login with given email and Password --> From Register Process
    Creates Playerobj for Mainloop.
  """
  handle ["login"], %{email: _, password: _} = args , client, state do
    Logger.info "Player module login_self email #{args.email}"
    query =
      from(
        p in PlayerLogin,
        where: p.email == ^args.email and p.passwortMD5Hash == ^args.password, 
        select: %{nickname: p.nickname,id: p.id}
      )
    response = Repo.one(query)
    Logger.info "DB Response for login query #{inspect response}"
    case response do 
      %{id: id, nickname: nickname}  ->
        player = %{
                  name: nickname,
                  #Right place for Socket .. Not Sure
                  socket: client.socket, 
                  login_type: :self,
                  id: id
                }
          Logger.info "Login new player #{nickname} with id #{id}"
          %{result_code: :ok, result: true,  state: Map.put(client, :player, player)}
        nil ->
          Logger.info "No positive Login player #{args.email} with passwortMD5Hash #{args.password}"
          %{result_code: :ok, result: false}
      _->
        %{result_code: :error, result: nil}
    end
  end
   @doc """
    Generic Error Handler
  """
  handle _, _ = args , client, state do
    %{result_code: :error, result: :wrong_function_call}
  end 
end
