# ExHttp

Simple HTTP server for Elixir

## Installation

If [available in Hex](https://hex.pm/docs/publish), the package can be installed
by adding `ex_http` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:ex_http, "~> 0.1.0"}
  ]
end
```

## Example
A code for a simple 1-page site:
```elixir
defmodule ExHttpTest do
  use Application
  alias ExHttp.Router.Node
  alias ExHttp.Http.Response

  def index _req do
    %Response{
      body: "<h1>Index page</h1>"
    }
    |> Response.content_type("text/html")
  end

  @impl true
  def start _type, _args do
    router = %Node{}
    |> Node.add_route([], &ExHttpTest.index/1)
    # Each piece of URL must be a separate string in an array instead of being separated with slash
    children = [
      {ExHttp, host: :loopback, router: router}
    ]
    Supervisor.start_link children, strategy: :one_for_one
  end
end
```
