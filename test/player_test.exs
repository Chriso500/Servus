defmodule ServusTest do
  use ExUnit.Case
  alias Servus.Serverutils
  alias Servus.Message

  setup_all do
    connect_opts = [
      :binary,
      packet: 4,
      active: false,
      reuseaddr: true
    ]

    {:ok, socket_alice} = :gen_tcp.connect('localhost', 3334, connect_opts)
    {:ok, [
      alice: %{raw: socket_alice, type: :tcp},
    ]}
  end

  test "integration test (TCP) for the Player Module", context do
    # Alice joins the game by sending the 'join'
    # message
    assert :ok == Serverutils.send(context.alice, "join", "alice")

    assert :ok == Serverutils.send(context.alice, "player_register", "Alice B. Cooper")

    assert(
      %Message{type: "player_registered", value: 0, target: nil} == 
      Serverutils.recv(context.alice, parse: true, timeout: 100)
    )
  end
end
