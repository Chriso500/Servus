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
end
