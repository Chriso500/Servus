defmodule Player_Userdata do
  @moduledoc """
  
  """
  alias Servus.{Repo, PlayerUserdata}
  use Servus.Module 
  require Logger
  import Ecto.Query, only: [from: 2]

  @configPUD Application.get_env(:servus, :player_userdata)
      #No Testmode memory for player
  register ["player","userdata"]
  @doc """
   Create SQL DB Connection
   Create Table Players @ Startup if needed
   Adds Fiels to Table if needed
  """
  def startup() do
    Logger.info "Player_userdata module registered"
  end

   handle ["picture"], %{internal_user_id: _} = args , client, state do
    Logger.info "FB_Picutre for id #{args.internal_user_id}"
    query =
      from(
        pU in PlayerUserdata,
        where: pU.player_id == ^args.internal_user_id, 
        select: %{mainpicture: pU.mainpicture,player_id: pU.player_id}
      )
    response = Repo.one(query)
    Logger.info "DB Response for player_userdata query #{inspect response}"
    case response do 
      %{mainpicture: mainpicture, player_id: id}  ->
          case File.read "#{@configPUD.picturepath}/#{mainpicture}" do
            {:ok, fileRawValue} ->
              Logger.info "Fileread complete"
              %{result_code: :ok, result:  %{id: id, picture: :binary.bin_to_list(fileRawValue)}}
            _->
               Logger.info "Other Error: Filereading?!?"
              %{result_code: :ok, result: :no_pic_for_id_file_error}
          end
        nil ->
          %{result_code: :ok, result: :no_pic_for_id}
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