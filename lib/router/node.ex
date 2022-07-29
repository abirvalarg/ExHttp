defmodule ExHttp.Router.Node do
  defstruct index: nil, paths: %{}

  @type t :: %ExHttp.Router.Node{
    index: nil | any,
    paths: %{String.t => t}
  }

  @spec add_route(t, [String.t], any) :: t
  def add_route self, [], func do
    %__MODULE__{ self | index: func }
  end

  def add_route self, [ path | rest ], func do
    next = (self.paths[path] || %__MODULE__{})
    |> add_route(rest, func)

    %__MODULE__{ self | paths: Map.put_new(self.paths, path, next) }
  end

  @spec add_node(t, [String.t], any) :: t
  def add_node self, [ path ], node do
    %__MODULE__{ self | paths: Map.put_new(self.paths, path, node) }
  end

  def add_node self, [ path | rest ], node do
    next = (self.paths[path] || %__MODULE__{})
    |> add_node(rest, node)

    %__MODULE__{ self | paths: Map.put_new(self.paths, path, next) }
  end
end

defimpl ExHttp.Router, for: ExHttp.Router.Node do
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
end
