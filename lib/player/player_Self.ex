defmodule Player_Self do
  @moduledoc """
  
  """  
  alias Servus.Serverutils
  alias Servus.SQLLITE_DB_Helper
  use Servus.Module 
  require Logger

  @config Application.get_env(:servus, :database)

  @db "file:#{@config.rootpath}/player.sqlite3#{@config.testmode}"

  register ["player","self"]
   @doc """
   Create SQL DB Connection
   Create Table Players @ Startup if needed
   Adds Fiels to Table if needed
  """
  def startup do
    Logger.info "Player module registered: #{@db}"

    {:ok, db} = Sqlitex.Server.start_link(@db)

    case Sqlitex.Server.exec(db, "CREATE TABLE players (id INTEGER PRIMARY KEY AUTOINCREMENT, nickname TEXT ,  internalPlayerKey TEXT, login_email TEXT UNIQUE, passwortMD5Hash Text, created_on INTEGER DEFAULT CURRENT_TIMESTAMP)") do
      :ok -> Logger.info "Table players created Self"
      {:error, {:sqlite_error, 'table players already exists'}} -> 
        Logger.info "Table players already exists. Adding new Login Email Columns if needed"
        SQLLITE_DB_Helper.findAndAddMissingColumns(db,[%{columnName: "login_email", columnType: "TEXT", constraint: "UNIQUE"},%{columnName: "passwortMD5Hash", columnType: "TEXT" }],"Players")
    end

    %{db: db} # Return module state here - db pid is used in handles
  end
  @doc """
   Register new Client with email and password and nickname 
   Returns id for Login
  """
  handle ["register"], %{nick: _, email: _, password: _ } = args , client, state do
    insert_stmt = "INSERT INTO players(nickname,login_email,passwortMD5Hash) VALUES ('#{args.nick}','#{args.email}','#{Serverutils.get_md5_hex(args.password)}')"
    case Sqlitex.Server.exec(state.db, insert_stmt) do 
    :ok ->
      case Sqlitex.Server.query(state.db, "SELECT last_insert_rowid() as id") do
        {:ok, [result]}  ->
          Logger.info "Create new player #{args.nick} with id #{result[:id]} and mail #{args.email}"
          %{result_code: :ok, result: %{id: result[:id]}}
      {:error, {:constraint, constraint}}->
          Logger.info "SQL Contraint Happend: #{inspect constraint}"
          %{result_code: :error, result: :constraint}
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
    Login with given email and Password --> From Register Process
    Creates Playerobj for Mainloop.
  """
  handle ["login"], %{email: _, password: _} = args , client, state do
    Logger.info "Player module login_self email #{args.email}"
    select_stmt = "Select count(*)as anzahl, nickname, id  FROM players  where login_email = '#{args.email}' and passwortMD5Hash= '#{Serverutils.get_md5_hex(args.password)}'"
    tmp = Sqlitex.Server.query(state.db, select_stmt)
    case tmp do 
      {:ok, [result]}  ->
        if result[:anzahl] == 1 do
          player = %{
                    name: result[:nickname],
                    #Right place for Socket .. Not Sure
                    socket: client.socket, 
                    login_type: :self,
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
