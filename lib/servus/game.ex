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
        if :hiscore in opts[:features] do
          @doc """
          Forward all register_player events to the appropriate module (Player).
          """
          def hiscore_achieve(player, score, state) do
            require Logger
            require Servus.Serverutils
            Logger.debug "Player #{player} achieved score #{score}"
            Servus.Serverutils.call("hiscore", "put", %{module: __MODULE__, player: player, score: score})
            Servus.Serverutils.send(state.socket, ["hiscore", "achieved"], nil)
          end
        end
      end
    end
  end
end
