defmodule Player do
  @moduledoc """
  
  """
  use Servus.Module 
  require Logger

  @config Application.get_env(:servus, :database)
  @db "file:#{@config.rootpath}/player.sqlite3#{@config.testmode}"

  register "player"

  def startup do
    Logger.info "Player module registered: #{@db}"

    {:ok, db} = Sqlitex.Server.start_link(@db)

    case Sqlitex.Server.exec(db, "CREATE TABLE IF NOT EXISTS players (id INTEGER PRIMARY KEY AUTOINCREMENT, nick TEXT, facebook_token TEXT, facebook_id TEXT UNIQUE, facebook_mail TEXT UNIQUE, login_hash  TEXT, login_mail TEXT UNIQUE, created_on INTEGER DEFAULT CURRENT_TIMESTAMP)") do
      :ok -> Logger.info "Table players created"
      {:error, {:sqlite_error, 'table players  already exists'}} -> Logger.info "Table players already exists"
    end

    %{db: db} # Return module state here - db pid is used in handles
  end

  handlep "put", %{nick: _} = args , state do
    Logger.debug "Create new player #{args.nick}"
    insert_stmt = "INSERT INTO players(nick) VALUES ('#{args.nick}')"
    Sqlitex.Server.exec(state.db, insert_stmt)
    {:ok, [result]} = Sqlitex.Server.query(state.db, "SELECT last_insert_rowid() as id")
    result[:id]
  end

  handlep "add_facebook", %{player: _, facebook_token: _} = args , state do
    insert_stmt = "UPDATE players SET facebook_token = #{args.facebook_token} WHERE id = #{args.player}"
    Sqlitex.Server.exec(state.db, insert_stmt)
  end

  handlep "add_google", %{player: _, google_token: _} = args , state do
    insert_stmt = "UPDATE players SET google_token = #{args.google_token} WHERE id = #{args.player}"
    Sqlitex.Server.exec(state.db, insert_stmt)
  end

   handlep "reg_with_facebook", %{facebook_name: _, facebook_token: _, facebook_id: _, facebook_mail: _} = args , state do
    Logger.info "Player module reg_with_facebook"
    insert_stmt = "INSERT INTO players (nick,facebook_token,facebook_id,facebook_mail) VALUES ('#{args.facebook_name}','#{args.facebook_token}','#{args.facebook_id}','#{args.facebook_mail}')"
    if :ok == Sqlitex.Server.exec(state.db, insert_stmt) do
    {:ok, [result]} = Sqlitex.Server.query(state.db, "SELECT last_insert_rowid() as id")
    {:ok, result[:id]}
    else
    :error
    end
  end

  handlep "select_facebook", %{facebook_id: _} = args , state do
    Logger.info "Player module select_facebook"
    select_stmt = "Select * FROM players  where facebook_id = '#{args.facebook_id}'"
    Sqlitex.Server.query(state.db, select_stmt)
  end
   handlep "delete_facebook", %{facebook_id: _} = args , state do
    Logger.info "Player module delete_facebook"
    select_stmt = "Delete FROM players  where facebook_id = '#{args.facebook_id}'"
    Sqlitex.Server.query(state.db, select_stmt)
  end
  handlep "reg_with_origin", %{nick: _, login_hash: _, login_mail: _} = args , state do
    Logger.info "Player module reg_with_origin"
    insert_stmt = "INSERT INTO players (nick,login_hash,login_mail) VALUES ('#{args.nick}','#{args.login_hash}','#{args.login_mail}')"
    if :ok == Sqlitex.Server.exec(state.db, insert_stmt) do
    {:ok, [result]} = Sqlitex.Server.query(state.db, "SELECT last_insert_rowid() as id")
    {:ok, result[:id]}
    else
    :error
    end
  end

  handlep "select_origin", %{login_mail: _} = args , state do
    Logger.info "Player module select_origin"
    select_stmt = "Select * FROM players  where login_mail = '#{args.login_mail}'"
    Sqlitex.Server.query(state.db, select_stmt)
  end
   handlep "delete_origin", %{login_mail: _} = args , state do
    Logger.info "Player module delete_origin"
    select_stmt = "Delete FROM players  where login_mail = '#{args.login_mail}'"
    Sqlitex.Server.query(state.db, select_stmt)
  end


  @moduledoc """
    The password should be ciphered before.
  """
  handlep "add_password", %{player: _, password: _} = args , state do
    insert_stmt = "UPDATE players SET password = #{args.password} WHERE id = #{args.player}"
    Sqlitex.Server.exec(state.db, insert_stmt)
  end
end
