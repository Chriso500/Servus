defmodule HiScoreTest do
  use ExUnit.Case
  alias Servus.Serverutils
  alias Servus.Message

  require Logger

  setup_all do
    connect_opts = [
      :binary,
      packet: 4,
      active: false,
      reuseaddr: true
    ]

    {:ok, socket_alice} = :gen_tcp.connect('localhost', 3334, connect_opts)
    {:ok, socket_bob} = :gen_tcp.connect('localhost', 3334, connect_opts)
    {:ok, [
      alice: %{raw: socket_alice, type: :tcp},
      bob: %{raw: socket_bob, type: :tcp}
    ]}
  end

  test "integration test (TCP) for the HiScore Module", context do
    # Alice joins the game by sending the 'join'
    # message

    #assert :ok == Serverutils.send(context.alice, ["player","register"], "Alice B. Cooper")

    assert :ok == Serverutils.send(context.alice, "join", "alice")

    assert :ok == Serverutils.send(context.bob, "join", "bob")

    assert(
      %Message{type: "start", value: "bob", target: nil} == 
      Serverutils.recv(context.alice, parse: true, timeout: 100)
    )

    assert(
      %Message{type: "start", value: "alice", target: nil} == 
      Serverutils.recv(context.bob, parse: true, timeout: 100)
    )

    turn(context.bob, context.alice, 1)
    turn(context.alice, context.bob, 7)
    turn(context.bob, context.alice, 2)
    turn(context.alice, context.bob, 7)
    turn(context.bob, context.alice, 3)
    turn(context.alice, context.bob, 4)
    turn(context.bob, context.alice, 5)
    turn(context.alice, context.bob, 7)
    turn(context.bob, context.alice, 6)

    assert(
      %Message{type: "turn", value: nil, target: nil} == 
      Serverutils.recv(context.alice, parse: true, timeout: 100)
    )

    # Bob turn
    assert :ok == Serverutils.send(context.alice, "put", 7)

    assert(
      %Message{type: "win", value: nil, target: nil} == 
      Serverutils.recv(context.alice, parse: true, timeout: 100)
    )

    assert(
      %Message{type: "set", value: 7, target: nil} == 
      Serverutils.recv(context.bob, parse: true, timeout: 100)
    )

    assert(
      %Message{type: "loose", value: nil, target: nil} == 
      Serverutils.recv(context.bob, parse: true, timeout: 100)
    )

    #assert :ok == Serverutils.call("hiscore", "put", %{module: 'sample game', player: id, score: 1337})

    #assert :ok == Serverutils.send(context.alice, ["hiscore","achieve"], %{player: id, score: 1337})

    #assert(
    #  %Message{type: ["hiscore", "achieved"], value: nil, target: nil} =
    #    Serverutils.recv(context.alice, parse: true, timeout: 100)
    #)
  end

  def turn(player1, player2, field) do
    assert(
      %Message{type: "turn", value: nil, target: nil} == 
      Serverutils.recv(player1, parse: true, timeout: 100)
    )

    # Bob turn
    assert :ok == Serverutils.send(player1, "put", field)

    assert(
      %Message{type: "set", value: field, target: nil} == 
      Serverutils.recv(player2, parse: true, timeout: 100)
    )
  end
end
