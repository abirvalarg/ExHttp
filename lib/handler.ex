defmodule ExHttp.Handler do
  @moduledoc """
  This module is used internally to handle the request and pass it to
  the handler
  """

  use GenServer
  alias ExHttp.Http.{Response, Request}
  alias ExHttp.Router

  defstruct client: nil, request: nil, buffer: "", router: nil

  @impl true
  def init [ client: client, router: router ] do
    { :ok, %__MODULE__{ client: client, router: router } }
  end

  @impl true
  def handle_info { :tcp, _sock, msg }, state do
    buffer = state.buffer <> msg
    request = state.request

    { buffer, request } = cond do
      request -> { "", Request.add_body(request, buffer) }
      String.contains?(buffer, "\r\n\r\n") ->
        with [ head, body ] <- String.split(buffer, "\r\n\r\n", parts: 2) do
          headers = String.split(head, "\r\n")
          request = List.foldl(headers, request, fn line, req -> Request.add_header req, line end)
          |> Request.add_body(body)
          { "", request }
        end
      true -> { buffer, nil }
    end

    { request, response } = case request do
      nil -> { nil, nil }
      { :ok, request } ->
        if Request.body_complete? request do
          path = String.split request.uri, "/", trim: true
          response = Router.route state.router, request, path
         { nil, response }
        else
          { request, nil }
        end
      { :error, status } -> { nil, Response.from_status(status) }
    end

    if response do
      response = to_string response
      :gen_tcp.send state.client, response
    end

    { :noreply, %__MODULE__{ state | request: request, buffer: buffer } }
  end

  @impl true
  def handle_info { :tcp_closed, _sock }, state do
    { :stop, :normal, state }
  end

  def terminate state do
    :gen_tcp.close state.client
  end
end
