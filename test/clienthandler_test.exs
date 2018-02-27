defmodule ClientHandlerTests do
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
  
    test "Wrong ModuleName", context do
      #Wrong first Account
      assert :ok == Serverutils.send(context.alice,["nothing", "there"], ["register"], %{})
      assert {:ok , returnMessage} = Serverutils.recv(context.alice)
      assert {:ok , data} = Poison.decode(returnMessage, as: %Servus.Message {}, keys: :atoms!) 
      assert %{Value: "generic_module_error", Target: _ , Type: _} = data
    end
    test "Wrong FunctionName", context do
      #Wrong first Account
      assert :ok == Serverutils.send(context.alice,["player", "self"], ["register2"], %{nick: "John Doe", email: "test@test.com", password: "Hello1234!"})
      assert {:ok , returnMessage} = Serverutils.recv(context.alice)
      assert {:ok , data} = Poison.decode(returnMessage, as: %Servus.Message {}, keys: :atoms!) 
      assert %{Value: %{result: "error", value: "wrong_function_call"}, Target: _ , Type: _} = data
    end
    test "Wrong FunctionVariableName", context do
      #Wrong first Account
      assert :ok == Serverutils.send(context.alice,["player", "self"], ["register"], %{nick2: "John Doe", email: "test@test.com", password: "Hello1234!"})
      assert {:ok , returnMessage} = Serverutils.recv(context.alice)
      assert {:ok , data} = Poison.decode(returnMessage, as: %Servus.Message {}, keys: :atoms!) 
      assert %{Value: %{result: "error", value: "wrong_function_call"}, Target: _ , Type: _} = data
    end
end