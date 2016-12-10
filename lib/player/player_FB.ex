defmodule Player_FB do
  @moduledoc """
  
  """
  use Servus.Module 
  require Logger

  @config Application.get_env(:servus, :database)
  @configFB Application.get_env(:servus, :facebook)
  #No Testmode memory for player
  @db "file:#{@config.rootpath}/player.sqlite3#{@config.testmode}"
  register ["player","fb"]
  @doc """
   Create SQL DB Connection
   Create Table Players @ Startup if needed
   Adds Fiels to Table if needed
  """
  def startup do
    Logger.info "Player_FB module registered: #{@db}"

    {:ok, db} = Sqlitex.Server.start_link(@db)

    case Sqlitex.Server.exec(db, "CREATE TABLE IF NOT EXISTS players (id INTEGER PRIMARY KEY AUTOINCREMENT, nickname TEXT, internalPlayerKey TEXT, facebook_token TEXT, facebook_id TEXT UNIQUE, login_email TEXT UNIQUE,facebook_token_expires NUMBER, created_on INTEGER DEFAULT CURRENT_TIMESTAMP)") do
      :ok -> Logger.info "Table players created"
      {:error, {:sqlite_error, 'table players  already exists'}} -> 
        Logger.info "Table players already exists. Adding new Login Facebook Columns if needed"
        SQLLITE_DB_Helper.findAndAddMissingColumns(db,[%{columnName: "facebook_token", columnType: "TEXT" },%{columnName: "facebook_id", columnType: "TEXT UNIQUE" },%{columnName: "login_email", columnType: "TEXT UNIQUE" },%{columnName: "facebook_token_expires", columnType: "NUMBER" }],"players")
    end

    %{db: db} # Return module state here - db pid is used in handles
  end
  @doc """
   Check if given Facebook and ID are valid
   Rund Facebook me with token
   if token is valid check if id from request and id from functioncall are equal
  """
  defp checkFBID(fb_id, token) do
    ffb_response = HTTPotion.get "https://graph.facebook.com/me?fields=id&access_token=#{token}"
    Logger.info "Facebook response to token #{token} response #{ffb_response.body}"
    case ffb_response do
     %{body: body, headers: ffb_id , status_code: statCode}  ->
      try do
        poison_data = Poison.decode(body, keys: :atoms) 
        case poison_data do
          {:ok, %{id: ffb_id}} ->
             if ffb_id == fb_id do
                Logger.info "Facebook identity check was sucessful"
                :ok
             else
                Logger.info "Not same ID #{fb_id} as fb_ID #{ffb_id}"
                :wrongFB
              end
          _->
            Logger.info "Problem with Json interpretation #{inspect poison_data}"
            :wrongFB
          end
      rescue
        e in ArgumentError -> 
        Logger.info "Error with JSON Decoder #{inspect e}"
        :wrongFB
      end
    _->
      Logger.info "Error with FB ID Check resp: #{inspect ffb_response}"
      :wrongFB
    end
  end

  @doc """
   Run Facebook Debugtoken to get Token lifetime informations
  """
  defp checkToken(token) do
    ffb_response = HTTPotion.get "https://graph.facebook.com/debug_token?input_token=#{token}&access_token=#{@configFB.app_token}"
    Logger.info "Facebook DEBUG TOKEN response to token #{token} response #{ffb_response.body}"
    case ffb_response do
     %{body: body, headers: ffb_id , status_code: statCode}  ->
      try do
        poison_data = Poison.decode(body, keys: :atoms) 
        case poison_data do
          {:ok, %{data: data}} ->
            unixActTimeStamp = :os.system_time(:seconds)
            %{timeleft: data.expires_at-unixActTimeStamp, is_valid: data.is_valid, timestamp: data.expires_at}
          _->
            Logger.info "Unexpected Answer in JSON Format #{inspect poison_data}"
            :wrongFB
          end
      rescue
        e in ArgumentError -> 
        Logger.info "Error with JSON Decoder #{inspect e}"
        :wrongFB
        e in KeyError -> 
        Logger.info "Error in FB Return #{inspect e}"
        :wrongFB
      end
    _->
      Logger.info "Error with FB ID Check resp: #{inspect ffb_response}"
      :wrongFB
    end 
  end
  @doc """
   Request a long living token from other clienttoken
  """
  defp requestLongToken(token) do
    ffb_response = HTTPotion.get "https://graph.facebook.com/v2.8/oauth/access_token?grant_type=fb_exchange_token&client_id=#{@configFB.app_id}&client_secret=#{@configFB.app_secret}&fb_exchange_token=#{token}"
    Logger.info "Facebook Request new Token with token #{token} response #{ffb_response.body}"
    case ffb_response do
     %{body: body, headers: ffb_id , status_code: statCode}  ->
      try do
        poison_data = Poison.decode(body, keys: :atoms) 
        case poison_data do
          {:ok, %{access_token: access_token, expires_in: expires_in, token_type: _}} ->
            unixActTimeStamp = :os.system_time(:seconds)
            expires_at = expires_in + unixActTimeStamp
            %{result: :ok, access_token: access_token, expires_at: expires_at }
          _->
            Logger.info "Unexpected Answer in JSON Format  #{inspect poison_data}"
            :wrongFB
          end
      rescue
        e in ArgumentError -> 
        Logger.info "Error with JSON Decoder #{inspect e}"
        :wrongFB
      end
    _->
      Logger.info "Error with FB ID Check resp: #{inspect ffb_response}"
      :wrongFB
    end 
  end
  @doc """
   Run Facebook me to get clientinformation like name and mail
  """
  defp facebookME(token) do
    ffb_response = HTTPotion.get "https://graph.facebook.com/me?fields=name,email&access_token=#{token}"
    Logger.info "Facebook ME response to token #{token} response #{ffb_response.body}"
    case ffb_response do
     %{body: body, headers: ffb_id , status_code: statCode}  ->
      try do
        poison_data = Poison.decode(body, keys: :atoms) 
        case poison_data do
          {:ok, data} ->
            Logger.info "Facebook ME was sucessful #{inspect data}"
            {:ok, data} 
          _->
            Logger.info "Problem with Json interpretation #{inspect poison_data}"
            :wrongFB
          end
      rescue
        e in ArgumentError -> 
        Logger.info "Error with JSON Decoder #{inspect e}"
        :wrongFB
      end
    _->
      Logger.info "Error with FB ME resp: #{inspect ffb_response}"
      :wrongFB
    end
  end
  @doc """
   Function combines FB functions
   First check if generall answer is ok (given from function before)
   if not pass value trough function
   if :ok check Token for Information
   if token lasts only less then 1 Month 
   then request new Long living Token
  """
  defp checkRequestToken(checkAnswer, actToken) do
    case checkAnswer do
      :ok ->
        result = checkToken(actToken)
        case result do
          %{timeleft: tleft, is_valid: true, timestamp: expires_at} ->
            #Unix timestamp 1 Monat(30,44 DAYS) 2.629.743 Sekunden
            if tleft > 2629742 do
              Logger.info "Token last longer than one month"
              %{result: :ok , access_token: actToken,expires_at: expires_at}
            else
              Logger.info "Token last not longer than one month --> Regnerate"
              requestLongToken(actToken)
            end
          %{timeleft: _, is_valid: false, timestamp: _} ->
            :requestNewToken
        _->
            result
        end
      _-> 
        checkAnswer
    end
  end

  @doc """
   Register new Client with Facebook ID and token
   First Check if Token and ID ist valid
   Second Generate new Long Lifing Token
   Get Email and Name from Facebook for Insert
   Add everything to the Db 
   Returns id and new Long Token for Login
  """
  handle ["register"], %{fb_id: _, token: _ } = args , client, state do
    fb_resp = checkFBID(args.fb_id,args.token)
    fb_resp = checkRequestToken(fb_resp,args.token)
    case fb_resp do
      %{result: :ok, access_token: access_token, expires_at: expires_at } ->
        fb_me_resp = facebookME(access_token)
        case fb_me_resp do
          {:ok, data} ->
          insert_stmt = "INSERT INTO players(nickname,login_email,facebook_id,facebook_token,facebook_token_expires) VALUES ('#{data.name}','#{data.email}','#{args.fb_id}', '#{access_token}', #{expires_at})"        
            case Sqlitex.Server.exec(state.db, insert_stmt) do 
            :ok ->
              case Sqlitex.Server.query(state.db, "SELECT last_insert_rowid() as id") do
                {:ok, [result]}  ->
                  Logger.info "Create new player #{data.name} with id #{result[:id]} and mail #{data.email} and facebook_id #{args.fb_id} and token #{access_token} expires_at #{expires_at}"
                  %{result_code: :ok, result: %{id: result[:id], newToken: access_token}}
                _ ->
                  %{result_code: :error, result: nil}
              end
            {:error, {:constraint, constraint}} ->
              Logger.info "SQL Contraint Happend: #{inspect constraint}"
              %{result_code: :error, result: :constraint}
            {:error, {:sqlite_error, error}} -> 
              Logger.info "SQL ERROR Happend: #{inspect error}"
              %{result_code: :error, result: error}
            _->
              Logger.info "Other Error?!?"
              %{result_code: :error, result: nil}
            end
        _->
          Logger.info "adadsd#{inspect fb_me_resp}"
          Logger.info "FB Error response #{inspect fb_me_resp}"
          %{result_code: :error, result: nil}
        end
        
      :requestNewToken -> 
        Logger.info "FB Error old Token #{inspect fb_resp}"
        %{result_code: :error, result: :requestNewToken}
      :wrongFB -> 
        Logger.info "FB Error response #{inspect fb_resp}"
        %{result_code: :error, result: :wrongFB}
      _-> 
        Logger.info "FB Error response #{inspect fb_resp}"
        %{result_code: :error, result: nil}
    end
  end
  @doc """
    Login with given Facebookid and Token --> From Register Process
    Look if Facebook id is already registerd
    Verify Token and id if valid
    Check if given Token is newer than oldone from DB
    #TBD Update DB with new token
    #TBD check if saved Token last longer than xxx --> otherwise renew!
    Creates Playerobj for Mainloop.
  """
  handle ["login"], %{fb_id: _, token: _} = args , client, state do
    Logger.info "Player module login_fb id #{args.fb_id} and token #{args.token}"
    select_stmt = "Select count(*)as anzahl, nickname, id, facebook_id, facebook_token, facebook_token_expires FROM players  where facebook_id = '#{args.fb_id}'"
    tmp = Sqlitex.Server.query(state.db, select_stmt)
    #Logger.info "DB TEST #{tmp}"
    case tmp do 
      {:ok, [result]}  ->
        if result[:anzahl] == 1 do
          if checkFBID(args.fb_id, args.token) ==:ok do
            player = %{
                      name: result[:nickname],
                      #Right place for Socket .. Not Sure
                      socket: client.socket, 
                      id: result[:id]
                    }
            Logger.info "Login new player #{result[:nickname]} with id #{result[:id]}"
            if args.token != result[:facebook_token] do
              resp = checkToken(args.token)
              if resp != :wrongFB && resp.timestamp > result[:facebook_token_expires] do
                #TBD UPDATE DB
              end
            end
            %{result_code: :ok, result: true,  state: Map.put(client, :player, player)}
          else
            %{result_code: :ok, result: :id_not_matched_to_token}
          end
       else
          %{result_code: :ok, result: :id_not_found}
       end
      {:error, {:sqlite_error, error}} ->
        Logger.info "DB ErrorCode #{inspect error}"
        %{result_code: :error, result: nil} 
      _->
        %{result_code: :error, result: nil}
    end
  end

end

