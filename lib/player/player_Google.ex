defmodule Player_Google do
  @moduledoc """
  
  """
  use Servus.Module 
  require Logger

  @config Application.get_env(:servus, :database)
   #No Testmode memory for player
  @db "file:#{@config.rootpath}/player.sqlite3"
  register "Google"

  def startup do
    Logger.info "Player_Google module registered: #{@db}"

  end

end
