defmodule Servus.Game do

  require Logger

  @moduledoc """
  A macro to be used with game state-machines. Will automatically
  start the state machine via the provided `start` function.
  """
  defmacro __using__(options) do
    quote do
      def start(players) do
        {:ok, pid} = :gen_fsm.start(__MODULE__, players, [])
        pid
      end

      @doc """
      Forward all abort events (player aborts connection) to the
      appropriate handler function (abort).
      """
      def handle_event({:abort, player}, _, state) do
        abort(player, state)
      end

      @doc """
      Default empty `terminate` implementation to allow game
      state machines to shutdown gracefully.
      """
      def terminate(_reason, _stateName, _stateData) do
        # This function intentionally left blank
      end

      @doc """
      Overridable by user. Will be invoked when one of the players
      aborts the connection.
      """
      def abort(player, state) do
        # Default: stop game state machine on connection abort
        {:stop, :shutdown, state}
      end

      defoverridable [abort: 2]

      # optional Game extensions, which will be loaded and applied if requested
      # e.g. use Servus.Game, features: [:player]
      opts = unquote(options)

      if opts[:features] do
        if :player in opts[:features] do
          @doc """
          Forward all register_player events to the appropriate module (Player).
          """
          def handle_event({:player_register, nick}, _, state) do
            require Logger
            Logger.debug("Register player name #{nick}")
            id = Servus.Serverutils.call("player", "put", %{nick: nick})
            Serverutils.send(state.socket, "player_registered", id)
          end
        end

        if :hiscore in opts[:features] do
          @doc """
          """
          def f_mod(players) do
          end
        end
      end
    end
  end
end
