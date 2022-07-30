defmodule ExHttp.Router.Node do
  defstruct index: nil, paths: %{}

  @type t :: %ExHttp.Router.Node{
    index: nil | any,
    paths: %{String.t => t}
  }
end

defimpl ExHttp.Router, for: ExHttp.Router.Node do
  alias ExHttp.Router.Node

  def route self, request, [] do
    if self.index do
      self.index.(request)
    else
      ExHttp.Http.Response.from_status :not_found
    end
  end

  def route self, request, [ path | rest ] do
    next = self.paths[path]
    if next do
      ExHttp.Router.route next, request, rest
    else
      ExHttp.Http.Response.from_status :not_found
    end
  end

  def add_route self, [], func do
    %Node{ self | index: func }
  end

  def add_route self, [ path | rest ], func do
    next = (self.paths[path] || %Node{})
    |> add_route(rest, func)

    %Node{ self | paths: Map.put_new(self.paths, path, next) }
  end

  def add_node self, [ path ], node do
    %Node{ self | paths: Map.put_new(self.paths, path, node) }
  end

  def add_node self, [ path | rest ], node do
    next = (self.paths[path] || %Node{})
    |> add_node(rest, node)

    %Node{ self | paths: Map.put_new(self.paths, path, next) }
  end
end
