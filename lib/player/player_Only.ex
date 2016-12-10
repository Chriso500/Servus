defmodule Player_Only do
  @moduledoc """
  
  """  
  alias Servus.Serverutils
  use Servus.Module 
  require Logger

  @config Application.get_env(:servus, :database)

  @db "file:#{@config.rootpath}/player.sqlite3#{@config.testmode}"
  register ["player","only"]

  @doc """
   Create SQL DB Connection
   Create Table Players @ Startup if needed
  """
  def startup do
    Logger.info "Player module registered: #{@db}"

    {:ok, db} = Sqlitex.Server.start_link(@db)

    case Sqlitex.Server.exec(db, "CREATE TABLE players (id INTEGER PRIMARY KEY AUTOINCREMENT, nickname TEXT,  internalPlayerKey TEXT, created_on INTEGER DEFAULT CURRENT_TIMESTAMP)") do
      :ok -> Logger.info "Table players created Only"
      {:error, {:sqlite_error, 'table players already exists'}} -> 
        Logger.info "Table players already exists"
    end

    %{db: db} # Return module state here - db pid is used in handles
  end

  @doc """
   Register new Client with nickanme 
   Returns unique key and id for Logins etc --> Key should be saved in APP
  """
  handle ["register"], %{nick: _} = args , client, state do
    playerKey = Serverutils.get_unique_id 
    insert_stmt = "INSERT INTO players(nickname,internalPlayerKey) VALUES ('#{args.nick}','#{playerKey}')"
    case Sqlitex.Server.exec(state.db, insert_stmt) do 
    :ok ->
      case Sqlitex.Server.query(state.db, "SELECT last_insert_rowid() as id") do
        {:ok, [result]}  ->
          Logger.info "Create new player #{args.nick} with id #{result[:id]} and key #{playerKey}"
          %{result_code: :ok, result: %{id: result[:id], key: playerKey}}
        {:error, {:sqlite_error, error}} -> 
          Logger.info "SQL ERROR Happend: #{inspect error}"
          %{result_code: :error, result: error}
        _ ->
          %{result_code: :error, result: nil}
      end
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
    select_stmt = "Select count(*)as anzahl, nickname, id  FROM players  where id = #{args.id} and internalPlayerKey= '#{args.key}'"
    tmp = Sqlitex.Server.query(state.db, select_stmt)
    #Logger.info "DB TEST #{tmp}"
    case tmp do 
      {:ok, [result]}  ->
        if result[:anzahl] == 1 do
          player = %{
                    name: result[:nickname],
                    #Right place for Socket .. Not Sure
                    socket: client.socket, 
                    id: result[:id]
                  }
          Logger.info "Login new player #{result[:nickname]} with id #{result[:id]}"
          %{result_code: :ok, result: true,  state: Map.put(client, :player, player)}
       else
          %{result_code: :ok, result: false}
       end
      {:error, {:sqlite_error, error}} ->
        Logger.info "DB ErrorCode #{inspect error}"
        %{result_code: :error, result: nil} 
      _->
        %{result_code: :error, result: nil}
    end
  end

end
