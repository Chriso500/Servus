defmodule PlayerOnlyTest do
  use ExUnit.Case
  alias Servus.Serverutils
  alias Servus.Message

  setup_all do
    connect_opts = [
      :binary,
      packet: :raw,
      active: false,
      reuseaddr: true
    ]

    {:ok, socket_alice} = :gen_tcp.connect('localhost', 3334, connect_opts)
    {:ok, [
      alice: %{raw: socket_alice, type: :tcp, socket: "dummy"},
    ]}
  end

  test "integration test (TCP) for the Player Only Module with register and login", context do
    #Register new Account
    assert :ok == Serverutils.send(context.alice,["player", "only"], ["register"], %{nick: "John Doe"})
    assert {:ok , returnMessage} = Serverutils.recv(context.alice)
    assert {:ok , data} = Poison.decode(returnMessage, as: %Servus.Message {}, keys: :atoms!) 
    assert %{Value: %{id: id, key: key}, Target: _ , Type: _} = data
    #Login test with new account
    assert :ok == Serverutils.send(context.alice, ["player", "only"], ["login"], %{id: id, key: key})
    assert {:ok , returnMessage} = Serverutils.recv(context.alice)
    assert {:ok , data} = Poison.decode(returnMessage, as: %Servus.Message {}, keys: :atoms!) 
    assert %{Value: true, Target: _ , Type: _} = data
    #Login test with new account but wrong id
    assert :ok == Serverutils.send(context.alice, ["player", "only"], ["login"], %{id: 6000, key: key})
    assert {:ok , returnMessage} = Serverutils.recv(context.alice)
    assert {:ok , data} = Poison.decode(returnMessage, as: %Servus.Message {}, keys: :atoms!) 
    assert %{Value: false, Target: _ , Type: _} = data
    #Login test with new account but wrong key
    assert :ok == Serverutils.send(context.alice, ["player", "only"], ["login"], %{id: id, key: 234234235235})
    assert {:ok , returnMessage} = Serverutils.recv(context.alice)
    assert {:ok , data} = Poison.decode(returnMessage, as: %Servus.Message {}, keys: :atoms!) 
    assert %{Value: false, Target: _ , Type: _} = data
    #Login test with new account but wrong id and key
    assert :ok == Serverutils.send(context.alice, ["player", "only"], ["login"], %{id: 6000, key: 5555})
    assert {:ok , returnMessage} = Serverutils.recv(context.alice)
    assert {:ok , data} = Poison.decode(returnMessage, as: %Servus.Message {}, keys: :atoms!) 
    assert %{Value: false, Target: _ , Type: _} = data
  end

  test "standalone test (sql-functions) for the Player Only Module", context do
    #Register new Account
    assert %{result: %{id: id, key: key}, result_code: :ok, state: nil}=Serverutils.call(["player", "only"], ["register"], %{nick: "Jane Doe"},nil)
    #Login with new account
    assert %{result: true, result_code: :ok, state: _}=Serverutils.call(["player", "only"], ["login"], %{id: id , key: key},context.alice)
    #Login test with new account but wrong key
    assert %{result: false, result_code: :ok, state: _}=Serverutils.call(["player", "only"], ["login"], %{id: id , key: 4444},context.alice)
    #Login test with new account but wrong id
    assert %{result: false, result_code: :ok, state: _}=Serverutils.call(["player", "only"], ["login"], %{id: 6000 , key: key},context.alice)
    #Login test with new account but wrong id and key
    assert %{result: false, result_code: :ok, state: _}=Serverutils.call(["player", "only"], ["login"], %{id: 6000 , key: 132123213},context.alice)
  end
end
