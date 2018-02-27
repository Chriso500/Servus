defmodule Player_Only do
  @moduledoc """
  
  """  
  alias Servus.Serverutils
  alias Servus.{Repo, PlayerLogin}
  use Servus.Module 
  require Logger
  import Ecto.Query, only: [from: 2]

  register ["player","only"]

  @doc """
   Create SQL DB Connection
   Create Table Players @ Startup if needed
  """
  def startup() do
    Logger.info "Player_only module registered"
  end

  @doc """
   Register new Client with nickanme 
   Returns unique key and id for Logins etc --> Key should be saved in APP
  """
  handle ["register"], %{nick: _} = args , client, state do
    playerKey = Serverutils.get_unique_id(7)
    newPlayer = PlayerLogin.add_Player_Only(%PlayerLogin{},%{nickname: args.nick, internalPlayerKey: playerKey})
    response = Repo.insert(newPlayer)
    Logger.info "DB Response for register insert #{inspect response}"
    case response do 
    {:ok, responsePL} ->
        Logger.info "Create new player #{args.nick} with id #{responsePL.id} and internalPlayerKey #{playerKey}"
        %{result_code: :ok, result:  %{id: responsePL.id, key: playerKey}}
    {:error, responsePL} ->
        Logger.info "Error Create new player #{args.nick} and internalPlayerKey #{playerKey}"
        %{result_code: :error, result: responsePL.errors}
    _->
      %{result_code: :error, result: nil}
    end
  end

  @doc """
    Login with given ID(Account) and key --> From Register Process
    Creates Playerobj for Mainloop.
  """
  handle ["login"], %{id: _, key: _} = args , client, state do
    Logger.info "Player module login_only id #{args.id} and key #{args.key}"
    query =
      from(
        p in PlayerLogin,
        where: p.id == ^args.id and p.internalPlayerKey == ^args.key, 
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
          Logger.info "No positive Login player #{args.id} with key #{args.key}"
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
