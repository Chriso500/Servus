defmodule Player_Userdata do
  @moduledoc """
  
  """
  alias Servus.Serverutils
  alias Servus.SQLLITE_DB_Helper
  use Servus.Module 
  require Logger

  @config Application.get_env(:servus, :database)
  @configPUD Application.get_env(:servus, :player_userdata)
      #No Testmode memory for player
  @db "file:#{@config.rootpath}/player.sqlite3#{@config.testmode}"
  register ["player","userdata"]
  @doc """
   Create SQL DB Connection
   Create Table Players @ Startup if needed
   Adds Fiels to Table if needed
  """
  def startup do
    Logger.info "Player_userdata module registered: #{@db}"

    {:ok, db} = Sqlitex.Server.start_link(@db)

    case Sqlitex.Server.exec(db, "CREATE TABLE player_userdata (id INTEGER UNIQUE, mainpicture Text, created_on INTEGER DEFAULT CURRENT_TIMESTAMP)") do
      :ok -> Logger.info "Table players_userdata created"
      {:error, {:sqlite_error, 'table player_userdata already exists'}} -> 
        Logger.info "Table player_userdata already exists."
        end
    %{db: db} # Return module state here - db pid is used in handles
  end

   handle ["picture"], %{internal_user_id: _} = args , client, state do
    #TBD Logincheck
    #Logger.info "Player module login_fb id #{args.fb_id} and token #{args.token}"
    select_stmt = "Select count(*)as anzahl, id, mainpicture FROM player_userdata where id = '#{args.internal_user_id}'"
    tmp = Sqlitex.Server.query(state.db, select_stmt)
    #Logger.info "DB TEST #{tmp}"
    case tmp do 
      {:ok, [result]}  ->
        if result[:anzahl] == 1 do
          case File.read "#{@configPUD.picturepath}/#{result[:mainpicture]}" do
            {:ok, fileRawValue} ->
              Logger.info "Fileread complete"
              %{result_code: :ok, result:  %{id: result[:id], picture: :binary.bin_to_list(fileRawValue)}}
            _->
               Logger.info "Other Error: Filereading?!?"
              %{result_code: :ok, result: :no_pic_for_id_file_error}
          end
        else
          %{result_code: :ok, result: :no_pic_for_id}
        end
      {:error, {:sqlite_error, error}} ->
        Logger.info "DB ErrorCode #{inspect error}"
        %{result_code: :error, result: nil} 
      _->
        %{result_code: :error, result: nil}
    end
  end
end