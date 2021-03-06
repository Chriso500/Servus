defmodule ServusWSTest do
  use ExUnit.Case
  alias Servus.Serverutils
  alias Servus.Message
  alias Socket.Web

  setup_all do
    socket_alice = Web.connect! "localhost", 3335
    socket_bob = Web.connect! "localhost", 3335

    {:ok, [
      alice: %{raw: socket_alice, type: :web, socket: socket_alice},
      bob: %{raw: socket_bob, type: :web, socket: socket_bob}
    ]}
  end

  test "integration test (WebSocket)", context do
   
    assert :ok == Serverutils.send(context.alice,["player", "only"], ["register"], %{nick: "John Doe"})
    assert {:ok , returnMessage} = Serverutils.recv(context.alice)
    assert {:ok , data} = Poison.decode(returnMessage, as: %Servus.Message {}, keys: :atoms!) 
    assert %{Value: %{id: id, key: key}, Target: _ , Type: _} = data
    #Login in new Account
    assert :ok == Serverutils.send(context.alice, ["player", "only"], ["login"], %{id: id, key: key})
    assert {:ok , returnMessage} = Serverutils.recv(context.alice)
    assert {:ok , data} = Poison.decode(returnMessage, as: %Servus.Message {}, keys: :atoms!) 
    assert %{Value: true, Target: _ , Type: _} = data    

    #Create Second Account
    assert :ok == Serverutils.send(context.bob,["player", "only"], ["register"], %{nick: "Jane Doe"})
    assert {:ok , returnMessage} = Serverutils.recv(context.bob)
    assert {:ok , data} = Poison.decode(returnMessage, as: %Servus.Message {}, keys: :atoms!) 
    assert %{Value: %{id: id, key: key}, Target: _ , Type: _} = data
    #Login in new Second Account
    assert :ok == Serverutils.send(context.bob, ["player", "only"], ["login"], %{id: id, key: key})
    assert {:ok , returnMessage} = Serverutils.recv(context.bob)
    assert {:ok , data} = Poison.decode(returnMessage, as: %Servus.Message {}, keys: :atoms!) 
    assert %{Value: true, Target: _ , Type: _} = data
    #Start Game
    assert :ok == Serverutils.send(context.alice, ["join"],nil)
    :timer.sleep(500)
    assert :ok == Serverutils.send(context.bob, ["join"],nil)
    #Recv Game Start from BOB
    assert {:ok , returnMessage} = Serverutils.recv(context.alice)
    assert {:ok , data} = Poison.decode(returnMessage, as: %Servus.Message {}, keys: :atoms!) 
    assert %Message{Type: "start", Value: "Jane Doe", Target: nil} ==  data
    #Recv Game Start from Allice
    assert {:ok , returnMessage} = Serverutils.recv(context.bob)
    assert {:ok , data} = Poison.decode(returnMessage, as: %Servus.Message {}, keys: :atoms!) 
    assert %Message{Type: "start", Value: "John Doe", Target: nil} ==  data
   


    turn(context.bob, context.alice, 1)
    turn(context.alice, context.bob, 7)
    turn(context.bob, context.alice, 2)
    turn(context.alice, context.bob, 7)
    turn(context.bob, context.alice, 3)
    turn(context.alice, context.bob, 4)
    turn(context.bob, context.alice, 5)
    turn(context.alice, context.bob, 7)
    turn(context.bob, context.alice, 6)
    turn(context.alice, context.bob, 7)

    assert {:ok , returnMessage} = Serverutils.recv(context.alice)
    assert {:ok , data} = Poison.decode(returnMessage, as: %Servus.Message {}, keys: :atoms!) 
    assert %Message{Type: "win", Value: nil, Target: nil} ==  data

    assert {:ok , returnMessage} = Serverutils.recv(context.bob)
    assert {:ok , data} = Poison.decode(returnMessage, as: %Servus.Message {}, keys: :atoms!) 
    assert %Message{Type: "loose", Value: nil, Target: nil} ==  data

  end

  def turn(player1, player2, field) do    
    assert {:ok , returnMessage} = Serverutils.recv(player1)
    assert {:ok , data} = Poison.decode(returnMessage, as: %Servus.Message {}, keys: :atoms!) 
    assert %Message{Type: "turn", Value: nil, Target: nil} ==  data

    assert :ok == Serverutils.send(player1, "put", field)

    assert {:ok , returnMessage} = Serverutils.recv(player2)
    assert {:ok , data} = Poison.decode(returnMessage, as: %Servus.Message {}, keys: :atoms!) 
    assert %Message{Type: "set", Value: field, Target: nil} ==  data
  end
end
