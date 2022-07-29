defprotocol ExHttp.Router do
  @spec route(any, ExHttp.Http.Request.t, [String.t]) :: ExHttp.Http.Response.t
  def route router, request, path
end
