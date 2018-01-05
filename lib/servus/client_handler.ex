defmodule Servus.ClientHandler do
  @moduledoc """
  Handles the socket connection of a client (player). All messages are
  received via tcp and interpreted as JSON.
  """
  alias Servus.PidStore
  alias Servus.ModuleStore
  alias Servus.Serverutils
  alias Servus.PlayerQueue
  alias Servus.Serverutils
  require Logger

  def run(state) do
    case Serverutils.recv(state.socket) do
      {:ok, message} ->
        data = Poison.decode(message, as: %Servus.Message {}, keys: :atoms) 
        Logger.info "Decode: #{inspect data}"
        case data do
          {:ok, %{Type: ["join"], Value: %{GameName: cardGame, GameMode: normal} }} ->
            if Map.has_key?(state, :player) do
              Logger.info "#{state.player.name} has joined the queue"
              PlayerQueue.push(state.queue, state.player)
            end
            run(state)
           {:ok, %{Type: ["join"]}} ->
            if Map.has_key?(state, :player) do
              Logger.info "#{state.player.name} has joined the queue"
              PlayerQueue.push(state.queue, state.player)
            end
            run(state)
          {:ok, %{Type: type, Target: target, Value: value}} ->
            if target == nil do
                try do
                  if not Map.has_key?(state, :fsm) do
                    pid = PidStore.get(state.player.id)
                    if pid != nil do
                      state = Map.put(state, :fsm, pid)
                    end
                  end
                  pid = state.fsm
                  :gen_fsm.send_event(pid, {state.player.id, type, value})
                rescue
                   e in _ -> 
                   Logger.error "External Game call not found and not queued operation: #{inspect type}"
                end
              run(state)
            else
              Logger.info "External Module call begin #{inspect target} operation: #{inspect type}"
              response = Serverutils.call(target,type,value,state)
              Logger.info "External Module call end #{inspect target} operation: #{inspect type} Response: #{inspect response}"
              if response.result_code == :error do
                Serverutils.send(state.socket, target, type, :error)
              else
                Serverutils.send(state.socket, target, type, response.result)
              end
              run(response.state)
            end
          _ ->
            Logger.warn "Invalid message format: #{message}"
            run(state)
        end
      {:error, err} ->
        # Client has aborted the connection
        # De-register it's ID from the pid store
        if Map.has_key?(state, :player) do
          # Remove him from the queue in case he's still there
          PlayerQueue.remove(state.queue, state.player)

          pid = PidStore.get(state.player.id)
          if pid != nil do
            # Notify the game logic about the player disconnect
            :gen_fsm.send_all_state_event(pid, {:abort, state.player})

            # Remove the player from the registry
            PidStore.remove(state.player.id)

            Logger.info "Removed player from pid store"
          end
        end
        Logger.warn "Unexpected clientside abort Error: #{inspect err}"
      _ ->
        Logger.warn "Unexpeted Return from recv func"
    end

  end
end

