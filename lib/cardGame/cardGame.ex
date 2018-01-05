defmodule Card do
   defstruct [:Name , :Id , :Value]
 end
defmodule CardGame do
  use Servus.Game
  require Logger

  alias Servus.Serverutils
  
  defp returnCardField() do
      cardfield = 
      [
        %Card{Name: "AcornTop",   Id: 1, Value: 1 },
        %Card{Name: "AcornUnder", Id: 2, Value: 1 },
        %Card{Name: "AcornAss",   Id: 3, Value: 1 },
        %Card{Name: "AcornKing",  Id: 4, Value: 1 },
        %Card{Name: "AcornTen",   Id: 5, Value: 1 },
        %Card{Name: "AcornNine",  Id: 6, Value: 1 },
        %Card{Name: "AcornEight", Id: 7, Value: 1 },
        %Card{Name: "AcornSeven", Id: 8, Value: 1 },
        %Card{Name: "HearthTop",   Id: 9, Value: 1 },
        %Card{Name: "HearthUnder", Id: 10, Value: 1 },
        %Card{Name: "HearthAss",   Id: 11, Value: 1 },
        %Card{Name: "HearthKing",  Id: 12, Value: 1 },
        %Card{Name: "HearthTen",   Id: 13, Value: 1 },
        %Card{Name: "HearthNine",  Id: 14, Value: 1 },
        %Card{Name: "HearthEight", Id: 15, Value: 1 },
        %Card{Name: "HearthSeven", Id: 16, Value: 1 },
        %Card{Name: "LeafTop",   Id: 17, Value: 1 },
        %Card{Name: "LeafUnder", Id: 18, Value: 1 },
        %Card{Name: "Leafss",   Id: 19, Value: 1 },
        %Card{Name: "LeafKing",  Id: 20, Value: 1 },
        %Card{Name: "LeafTen",   Id: 21, Value: 1 },
        %Card{Name: "LeafNine",  Id: 22, Value: 1 },
        %Card{Name: "LeafEight", Id: 23, Value: 1 },
        %Card{Name: "LeafSeven", Id: 24, Value: 1 },
        %Card{Name: "ShellTop",   Id: 25, Value: 1 },
        %Card{Name: "ShellUnder", Id: 26, Value: 1 },
        %Card{Name: "ShellAss",   Id: 27, Value: 1 },
        %Card{Name: "ShellKing",  Id: 28, Value: 1 },
        %Card{Name: "ShellTen",   Id: 29, Value: 1 },
        %Card{Name: "ShellNine",  Id: 30, Value: 1 },
        %Card{Name: "ShellEight", Id: 31, Value: 1 },
        %Card{Name: "ShellSeven", Id: 32, Value: 1 }
      ]
  end

  def init(players) do
    Logger.info "Initializing game state machine for CardGame"

    #[player1,player2,player3, player4] = players
    #fsm_state = %{playerOne: player1, playerTwo: player2, playerThree: player3, playerFour: player4}
    #Serverutils.send(player1.socket, ["AllJoined"], %{PlayerOne:player1.name,PlayerTwo:player2.name,PlayerThree:player3.name,PlayerFour:player4.name})
    #Serverutils.send(player2.socket, ["AllJoined"], %{PlayerOne:player1.name,PlayerTwo:player2.name,PlayerThree:player3.name,PlayerFour:player4.name})
    #Serverutils.send(player3.socket, ["AllJoined"], %{PlayerOne:player1.name,PlayerTwo:player2.name,PlayerThree:player3.name,PlayerFour:player4.name})
    #Serverutils.send(player4.socket, ["AllJoined"], %{PlayerOne:player1.name,PlayerTwo:player2.name,PlayerThree:player3.name,PlayerFour:player4.name})
    [player1] = players
    fsm_state = %{playerOne: player1}
    Serverutils.send(player1.socket, ["AllJoined"], %{PlayerOne: player1.name , PlayerTwo: player1.name,PlayerThree: player1.name,PlayerFour: player1.name})
    givecards(players)
    {:ok, :newGame, fsm_state}
  end

  defp givecards(playerOrder) do
    :random.seed(:erlang.now)
    cardField = returnCardField()
    #First Round 16 from 32 cards to share
    cardShareDTO= %{orderLeft: playerOrder, cardsLeft: cardField}
    cardShareDTO = giveOneRound(cardShareDTO)
    #Second Round 16 from 16 left cards to share
    giveOneRound(cardShareDTO)
  end

  defp giveOneRound(cardShareDTO) do
    Enum.reduce(cardShareDTO.orderLeft, cardShareDTO, fn(x, acc) ->  
      fourCards = Enum.take_random(acc.cardsLeft, 4)
      Logger.info inspect fourCards
      Serverutils.send(x.socket, ["GetCards"],fourCards) 
      cL = removeFromArray(acc.cardsLeft,fourCards)
      oL= removeFromArray(acc.orderLeft,x)
      %{orderLeft: oL, cardsLeft: cL}
    end)
  end
  defp removeFromArray(all,toDelete) do
    Enum.reduce(toDelete, all, fn(x, acc) -> List.delete(acc,x) end)
  end
  @doc """
  FSM is in state `newGame`
  """
  def newGame(state) do
    Logger.info "new Game CardGame started"
    {:next_state, :newGame, state}
  end
end
