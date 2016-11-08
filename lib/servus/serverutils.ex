defmodule Servus.Serverutils.TCP do

  require Logger
  @moduledoc """
  Implementation of send/3 and recv/2 for TCP sockets
  """

  @doc """
  Returns IP address associated with a socket (usually the
  client socket)
  """
  def get_address(socket) do
    {:ok, {address, _}} = :inet.peername(socket)
    address |> Tuple.to_list |> Enum.join "."
  end

  @doc """
  Sends a message via TCP socket. The message will always have
  the form `{"type": type,"value": value}`
  """
  def send(socket, type, value) do
    {:ok, json} = Poison.encode %{
      type: type,
      value: value
    }

    :gen_tcp.send socket, json
  end

  @doc """
  Wait for a message on a TCP socket. A timeout can be passed
  in the `opts`. The default timeout should be `:infinity`. If
  `opts[:parse]` is true then a data will be parsed as JSON and
  returned as a `Servus.Message` struct. Otherwise the data will
  be returned as string.
  """
    def recv(socket, opts) do
    length_result = :gen_tcp.recv(socket, 4, opts[:timeout])
    case length_result do
    {:ok, length_binary} ->
     <<length::integer-size(32)>> =  length_binary
     Logger.info "Packetlänge vorrausgeschickt: #{inspect length}"
      data_result = :gen_tcp.recv(socket, length, opts[:timeout])
       case data_result do
       {:ok, data} ->
       Logger.info "JSON String des Packets: #{inspect data}"
        #if opts[:parse] do
          {:ok, data}
        #else
         # data
        #end
      _->
        data_result
      end
    _ ->
      length_result
    end
  end
end

defmodule Servus.Serverutils.Web do
  @moduledoc """
  Implementation of send/3 and recv/1 for WebSocket connections
  """

  @doc """
  Returns IP address associated with a socket (usually the
  client socket)
  """
  def get_address(socket) do
    Servus.Serverutils.TCP.get_address(socket)
  end

  @doc """
  Sends a message via WebSocket. The message will always have
  the form `{"type": type,"value": value}`
  """
  def send(socket, type, value) do
    {:ok, json} = Poison.encode %{
      type: type,
      value: value
    }

    Socket.Web.send socket, {:text, json}
  end

  @doc """
  Wait for a message on a WebSocket connection. Other than TCP sockets
  this does not have a `:timeout` option. The `:parse` option however
  is available.
  """
  def recv(socket, opts) do
    result = Socket.Web.recv socket

    case result do
      {:ok, {:text, data}} ->
        if opts[:parse] do
          {:ok, msg} = Poison.decode data, as: Servus.Message
          msg
        else
          {:ok, data}
        end
      {:error, reason} ->
        result
      _ ->
        {:error, :unknown}
    end
  end
end

defmodule Servus.Serverutils do
  @moduledoc """
  A facade to hide all actual socket interactions and provide the
  same API for TCP and WebSockets (and more to come? UDP?)

  Also contains some utility functions (`get_unique_id/0`)
  """

  alias Servus.Serverutils.Web
  alias Servus.Serverutils.TCP
  alias Servus.ModuleStore
  require Logger

  # IDs
  # ###############################################
  def get_unique_id do
    :crypto.rand_bytes(4) |> :crypto.bytes_to_integer
  end
  # ###############################################


  # Addresses
  # ###############################################
  def get_address(%Socket.Web{socket: socket}) do
    Web.get_address(socket)
  end

  def get_address(socket) do
    TCP.get_address(socket)
  end
  # ###############################################


  # Send / Receive
  # ###############################################
  def send(socket, type, value) do
    case socket.type do
      :tcp -> TCP.send(socket.raw, type, value)
      :web -> Web.send(socket.raw, type, value)
    end
  end

  def recv(socket, opts \\ [parse: false, timeout: :infinity]) do
    case socket.type do
      :tcp -> TCP.recv(socket.raw, opts)
      :web -> Web.recv(socket.raw, opts)
    end
  end
  # ###############################################


  # Module call
  # ###############################################
  @doc """
  # call
  Sample Servus.Serverutils.call("hiscore", "put", %{module: _, player: _, score: _}) when "put" is a handlep callback
  """
  def call(target, type, value) do
    pid = ModuleStore.get(target)
    
    if pid != nil and Process.alive?(pid) do
      GenServer.call(pid, {:priv, type, value})
    else
      :error
    end
  end
  # ###############################################
end
