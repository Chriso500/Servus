defmodule TestModule_1P do
  use Servus.Game
  require Logger

  alias Servus.Serverutils

  def init(players) do
    Logger.info "Initializing game state machine for testModule"
    [player1] = players
    fsm_state = %{player1: player1, counter: 0}
    Serverutils.send(player1.socket, ["begin_Test"], player1.name)
    {:ok, :redo, fsm_state}
  end


  
  @doc """
  FSM is in state `p1`. Player 1 puts.
  Outcome: p2 state
  """
  def redo({id, ["sendData"], data}, state) do
    Logger.info "Data: #{inspect data} from id: #{inspect id}"
    Serverutils.send(state.player1.socket, ["reSendData"], data)
    {:next_state, :redo, state}
  end
  
end