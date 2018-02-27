defmodule PlayerSelfTest do
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

  test "integration test (TCP) for the Player Self Module with register and login", context do
    #Register new Account
    assert :ok == Serverutils.send(context.alice,["player", "self"], ["register"], %{nick: "John Doe", email: "test@test.com", password: "Hello1234!"})
    assert {:ok , returnMessage} = Serverutils.recv(context.alice)
    assert {:ok , data} = Poison.decode(returnMessage, as: %Servus.Message {}, keys: :atoms!) 
    assert %{Value: %{id: _}, Target: _ , Type: _} = data
    #Login test with new account
    assert :ok == Serverutils.send(context.alice, ["player", "self"], ["login"], %{email: "test@test.com", password: Serverutils.get_md5_hex("Hello1234!")})
    assert {:ok , returnMessage} = Serverutils.recv(context.alice)
    assert {:ok , data} = Poison.decode(returnMessage, as: %Servus.Message {}, keys: :atoms!) 
    assert %{Value: true, Target: _ , Type: _} = data
    #Login test with new account but wrong id
    assert :ok == Serverutils.send(context.alice, ["player", "self"], ["login"], %{email: "Wrong@wrong.de", password: Serverutils.get_md5_hex("Hello1234!")})
    assert {:ok , returnMessage} = Serverutils.recv(context.alice)
    assert {:ok , data} = Poison.decode(returnMessage, as: %Servus.Message {}, keys: :atoms!) 
    assert %{Value: false, Target: _ , Type: _} = data
    #Login test with new account but wrong key
    assert :ok == Serverutils.send(context.alice, ["player", "self"], ["login"], %{email: "test@test.com", password: Serverutils.get_md5_hex("Wrong!")})
    assert {:ok , returnMessage} = Serverutils.recv(context.alice)
    assert {:ok , data} = Poison.decode(returnMessage, as: %Servus.Message {}, keys: :atoms!) 
    assert %{Value: false, Target: _ , Type: _} = data
    #Login test with new account but wrong id and key
    assert :ok == Serverutils.send(context.alice, ["player", "self"], ["login"], %{email: "Wrong@wrong.de", password: Serverutils.get_md5_hex("Wrong!")})
    assert {:ok , returnMessage} = Serverutils.recv(context.alice)
    assert {:ok , data} = Poison.decode(returnMessage, as: %Servus.Message {}, keys: :atoms!) 
    assert %{Value: false, Target: _ , Type: _} = data
  end

  test "standalone test (sql-functions) for the Player Self Module", context do
    #Register new Account
    assert %{result: %{id: _}, result_code: :ok, state: nil}=Serverutils.call(["player", "self"], ["register"], %{nick: "Jane Doe", email: "test2@test.com", password: "Hello1234!"},nil)
    #Login with new account
    assert %{result: true, result_code: :ok, state: _}=Serverutils.call(["player", "self"], ["login"], %{email: "test2@test.com", password: Serverutils.get_md5_hex("Hello1234!")},context.alice)
    #Login test with new account but wrong id
    assert %{result: false, result_code: :ok, state: _}=Serverutils.call(["player", "self"], ["login"], %{email: "Wrong@wrong.de", password: Serverutils.get_md5_hex("Hello1234!")},context.alice)
    #Login test with new account but wrong key
    assert %{result: false, result_code: :ok, state: _}=Serverutils.call(["player", "self"], ["login"], %{email: "test2@test.com", password: Serverutils.get_md5_hex("Wrong!")},context.alice)
    #Login test with new account but wrong id and key
    assert %{result: false, result_code: :ok, state: _}=Serverutils.call(["player", "self"], ["login"], %{email: "Wrong@wrong.de", password: Serverutils.get_md5_hex("Wrong!")},context.alice)
  end
end
