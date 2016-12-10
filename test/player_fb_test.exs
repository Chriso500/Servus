defmodule PlayerFBTest do
  use ExUnit.Case
  require Logger
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

  test "integration test (TCP) for the Player FB Module with register and login", context do
    #Register new Account
    assert %{body: body, headers: _ , status_code: _}  = HTTPotion.get "https://graph.facebook.com/v2.8/1216077065136886/accounts/test-users?id=119663468525205&access_token=1216077065136886|yaVQhGi9fzy_N5YchZBH2xQwvzk"
    assert {:ok, data} = Poison.decode(body, keys: :atoms) 
    assert :ok == Serverutils.send(context.alice,["player", "fb"], ["register"], %{fb_id: "119663468525205", token: "#{Enum.at(data.data,0).access_token}" })
    assert {:ok , returnMessage} = Serverutils.recv(context.alice)
    assert {:ok , data} = Poison.decode(returnMessage, as: %Servus.Message {}, keys: :atoms!) 
    assert %{Value: %{id: 1, newToken: access_token}, Target: _ , Type: _} = data

  
    #Login test with new account
    assert :ok == Serverutils.send(context.alice, ["player", "fb"], ["login"], %{fb_id: "119663468525205", token: "#{access_token}"})
    assert {:ok , returnMessage} = Serverutils.recv(context.alice)
    assert {:ok , data} = Poison.decode(returnMessage, as: %Servus.Message {}, keys: :atoms!) 
    assert %{Value: true, Target: _ , Type: _} = data
    
    #Login test with wrong id account
    assert :ok == Serverutils.send(context.alice, ["player", "fb"], ["login"], %{fb_id: "00000000000000", token: "#{access_token}"})
    assert {:ok , returnMessage} = Serverutils.recv(context.alice)
    assert {:ok , data} = Poison.decode(returnMessage, as: %Servus.Message {}, keys: :atoms!) 
    assert %{Value: "id_not_found", Target: _ , Type: _} = data
    #Login test with wrong token
    assert :ok == Serverutils.send(context.alice, ["player", "fb"], ["login"], %{fb_id: "119663468525205", token: "-"})
    assert {:ok , returnMessage} = Serverutils.recv(context.alice)
    assert {:ok , data} = Poison.decode(returnMessage, as: %Servus.Message {}, keys: :atoms!) 
    assert %{Value: "id_not_matched_to_token", Target: _ , Type: _} = data
    #Login test with wrong id and token
    assert :ok == Serverutils.send(context.alice, ["player", "fb"], ["login"], %{fb_id: "00000000000000", token: "-"})
    assert {:ok , returnMessage} = Serverutils.recv(context.alice)
    assert {:ok , data} = Poison.decode(returnMessage, as: %Servus.Message {}, keys: :atoms!) 
    assert %{Value: "id_not_found", Target: _ , Type: _} = data
  end

  test "standalone test (sql-functions) for the Player FB Module", context do
    #Register new Account
    assert %{body: body, headers: _ , status_code: _}  = HTTPotion.get "https://graph.facebook.com/v2.8/1216077065136886/accounts/test-users?id=123818274774430&access_token=1216077065136886|yaVQhGi9fzy_N5YchZBH2xQwvzk"
    assert {:ok, data} = Poison.decode(body, keys: :atoms) 
    assert %{result: %{id: 2, newToken: access_token}, result_code: :ok, state: nil}=Serverutils.call(["player", "fb"], ["register"], %{fb_id: "123818274774430", token: "#{Enum.at(data.data,1).access_token}"},nil)
    #Login with new account
    assert %{result: true, result_code: :ok, state: _}=Serverutils.call(["player", "fb"], ["login"], %{fb_id: "123818274774430", token: "#{Enum.at(data.data,1).access_token}"},context.alice)
    #Login with new account and wrong id
    assert %{result: :id_not_found, result_code: :ok, state: _}=Serverutils.call(["player", "fb"], ["login"], %{fb_id: "-", token: "#{Enum.at(data.data,1).access_token}"},context.alice)
    #Login with new account and wrong token
    assert %{result: :id_not_matched_to_token, result_code: :ok, state: _}=Serverutils.call(["player", "fb"], ["login"], %{fb_id: "123818274774430", token: "-"},context.alice)
    #Login with new account and wrong id and token
    assert %{result: :id_not_found, result_code: :ok, state: _}=Serverutils.call(["player", "fb"], ["login"], %{fb_id: "-", token: "-"},context.alice)
  
  end
end
