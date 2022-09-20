defmodule ExHttp.Http.Request do
  @moduledoc """
  Represents an HTTP request
  """

  defstruct method: "GET", uri: "/", args: %{}, headers: %{}, cookies: %{}, content_len: nil, body: nil

  @type t :: %ExHttp.Http.Request{
    method: String.t,
    uri: String.t,
    args: %{String.t => String.t},
    headers: %{String.t => String.t},
    cookies: %{String.t => String.t},
    content_len: integer,
    body: String.t
  }
  @type req :: t | { :ok, t } | { :error, reason :: term }


  @spec add_header(req, binary) :: {:error, :bad_request} | {:ok, t()}
  @doc """
  Used internally to add header lines to the request objects
  """
  def add_header({ :ok, req }, line), do: add_header req, line

  def add_header nil, line do
    with [ method, uri, _ ] <- String.split(line, " ", trim: true) do
      { uri, args } = with [ uri, args ] <- String.split(uri, "?", parts: 2) do
        args = for pair <- String.split(args, "&") do
          with [ key, val ] <- String.split(pair, "=", parts: 2) do
            { :uri_string.percent_decode(key), :uri_string.percent_decode(val) }
          else
            [ key ] -> { key, "" }
          end
        end
        { uri, Enum.into(args, %{}) }
      else
        [ uri ] -> { uri, %{} }
      end
      { :ok, %__MODULE__{ method: method, uri: uri, args: args } }
    else
      _ -> { :error, :bad_request }
    end
  end

  def add_header self, line do
    with [ name, val ] <- String.split(line, ": ", parts: 2, trim: true) do
      self = case name do
        "Content-Length" -> %__MODULE__{ self | content_len: String.to_integer(val) }
        "Cookie" ->
          cookies = for pair <- String.split(val, "; ") do
            with [ name, val ] <- String.split(pair, "=") do
              { name, val }
            else
              [ name ] -> { name, "" }
            end
          end
          %__MODULE__{ self | cookies: Enum.into(cookies, %{}) }
        _ -> %__MODULE__{ self | headers: Map.put(self.headers, name, val) }
      end
      { :ok, self }
    else
      _ -> { :error, :bad_request }
    end
  end

  @spec add_body(req, String.t) :: { :ok, t } | { :error, :bad_request }
  @doc """
  Used internally to append data to request body
  """
  def add_body({ :ok, self }, buffer), do: add_body self, buffer
  def add_body({ :error, status }, _), do: { :error, status }
  def add_body self, buffer do
    body = self.body || ""
    { :ok, %__MODULE__{ self | body: body <> buffer } }
  end

  @spec data(t) :: { :ok, %{ String.t => String.t } } | { :error, :bad_request | :incomplete | :no_data }
  @doc """
  Decode data from request body. This method check `Content-Type` header. Only
  URL-encoded data is supported yet
  """
  def data self do
    if body_complete? self do
      type = self.headers["Content-Type"]
      with [ type | _ ] <- String.split(type, ";", trim: true) do
        case type do
          "application/x-www-form-urlencoded" -> { :ok, parse_urlencoded self.body }
          _ -> { :error, :bad_request }
        end
      else
        _ -> { :error, :no_data }
      end
    else
      { :error, :incomplete }
    end
  end

  defp parse_urlencoded body do
    data = for pair <- String.split(body, "&") do
      with [ key, value ] <- String.split(pair, "=") do
        { :uri_string.percent_decode(key), :uri_string.percent_decode(value) }
      else
        [ key ] -> { key, "" }
      end
    end
    Enum.into data, %{}
  end

  @spec body_complete?(t) :: boolean
  @doc """
  Used internally to check whether to wait for next piece of data or pass
  the request to the handler
  """
  def body_complete?(self), do: self.content_len == nil or self.content_len == String.length(self.body)
end
