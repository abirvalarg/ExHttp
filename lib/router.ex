defprotocol ExHttp.Router do
  @spec route(any, ExHttp.Http.Request.t, [String.t]) :: ExHttp.Http.Response.t
  def route router, request, path

  @spec add_route(any, [String.t], any) :: any
  def add_route router, path, func

  @spec add_node(any, [String.t], any) :: any
  def add_node router, path, node
end
