defmodule Echo do
  use Servus.Module 
  require Logger

  register "echo"

  def startup do
    Logger.info "Echo module registered"
    [] # Return module state here
  end

  handlep "echo", args, state do
    Logger.info "Echo module called"
    args
  end
   @doc """
    Generic Error Handler
  """
  handle _, _ = args , client, state do
    %{result_code: :error, result: :wrong_function_call}
  end 
end
