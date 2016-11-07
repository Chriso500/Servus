defmodule PlayerTest do
  use ExUnit.Case, seed: 0
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
    
    assert :ok == Serverutils.send(context.alice, ["player","register"], "Alice B. Cooper")

    assert(
      %Message{type: ["player", "registered"], value: 1, target: nil} == 
      Serverutils.recv(context.alice, parse: true, timeout: 100)
    )

    assert :ok == Serverutils.send(context.alice, ["player","anything"], nil)

    assert(
      %Message{type: ["player", "error"], value: "Unknown function: anything", target: nil} == 
      Serverutils.recv(context.alice, parse: true, timeout: 100)
    )
  end
  test "standalone test (sql-functions) for the Player Module", context do
    
    {tmpVar, _ } = Serverutils.call("player", "reg_with_facebook", %{facebook_name: "Test", facebook_token: "12345542", facebook_id: "XYZTT", facebook_mail: "Test@test.de"})
    assert :ok == tmpVar
    assert :error == Serverutils.call("player", "reg_with_facebook", %{facebook_name: "Test", facebook_token: "12345542", facebook_id: "XYZTT", facebook_mail: "Test@test.de"})
    {tmpVar, _ } = Serverutils.call("player", "select_facebook", %{facebook_id: "XYZTT"})
    assert :ok ==  tmpVar
    assert {:ok, []} == Serverutils.call("player", "delete_facebook", %{facebook_id: "XYZTT"})
    assert {:ok, []}==Serverutils.call("player", "select_facebook", %{facebook_id: "XYZTT"})
    #NORMAL LOGINS
    {tmpVar, _ }  = Serverutils.call("player", "reg_with_origin", %{nick: "Test", login_hash: "12345542", login_mail: "Test@test.de"})
    assert :ok ==  tmpVar
    :error == Serverutils.call("player", "reg_with_origin", %{nick: "Test", login_hash: "12345542", login_mail: "Test@test.de"})
    {tmpVar, _ } = Serverutils.call("player", "select_origin", %{login_mail: "XYZTT"})
    assert :ok ==  tmpVar
    assert {:ok, []} == Serverutils.call("player", "delete_origin", %{login_mail: "XYZTT"})
    assert {:ok, []}==Serverutils.call("player", "select_origin", %{login_mail: "XYZTT"})
  end
end
