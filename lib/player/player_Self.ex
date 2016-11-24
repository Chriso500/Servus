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

  def startup do
    Logger.info "Player module registered: #{@db}"

    {:ok, db} = Sqlitex.Server.start_link(@db)

    case Sqlitex.Server.exec(db, "CREATE TABLE players (id INTEGER PRIMARY KEY AUTOINCREMENT, nickname TEXT ,  internalPlayerKey TEXT, email TEXT UNIQUE, passwortMD5Hash Text, created_on INTEGER DEFAULT CURRENT_TIMESTAMP)") do
      :ok -> Logger.info "Table players created Self"
      {:error, {:sqlite_error, 'table players already exists'}} -> 
        Logger.info "Table players already exists. Adding new Columns"
        SQLLITE_DB_Helper.findAndAddMissingColumns(db,[%{columnName: "email", columnType: "TEXT" },%{columnName: "passwortMD5Hash", columnType: "TEXT" }],"Players")
    end

    %{db: db} # Return module state here - db pid is used in handles
  end

  handle ["register"], %{nick: _, email: _, password: _ } = args , client, state do
    insert_stmt = "INSERT INTO players(nickname,email,passwortMD5Hash) VALUES ('#{args.nick}','#{args.email}','#{Serverutils.get_md5_hex(args.password)}')"
    case Sqlitex.Server.exec(state.db, insert_stmt) do 
    :ok ->
      case Sqlitex.Server.query(state.db, "SELECT last_insert_rowid() as id") do
        {:ok, [result]}  ->
          Logger.info "Create new player #{args.nick} with id #{result[:id]} and mail #{args.email}"
          %{result_code: :ok, result: %{id: result[:id]}}
        _ ->
          %{result_code: :error, result: nil}
      end
    _->
      %{result_code: :error, result: nil}
    end
  end

  handle ["login"], %{email: _, password: _} = args , client, state do
    Logger.info "Player module login_self email #{args.email}"
    select_stmt = "Select count(*)as anzahl, nickname, id  FROM players  where email = '#{args.email}' and passwortMD5Hash= '#{Serverutils.get_md5_hex(args.password)}'"
    tmp = Sqlitex.Server.query(state.db, select_stmt)
    case tmp do 
      {:ok, [result]}  ->
        if result[:anzahl] == 1 do
          player = %{
                    name: result[:nickname],
                    #Right place for Socket .. Not Sure
                    socket: client.socket, 
                    id: result[:id]
                  }
          Logger.info "Create new player #{result[:nickname]} with id #{result[:anzahl]}"
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
