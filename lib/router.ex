defprotocol ExHttp.Router do
  @moduledoc """
  A protocol for router objects
  """

  @spec route(any, ExHttp.Http.Request.t, [String.t]) :: ExHttp.Http.Response.t
  @doc """
  Routes the request to the handler and returns the response object
  """
  def route router, request, path

  @spec add_route(any, [String.t], any) :: any
  @doc """
  Add a new handler
  """
  def add_route router, path, func

  @spec add_node(any, [String.t], any) :: any
  @doc """
  Add a route node of other type
  """
  def add_node router, path, node
end
