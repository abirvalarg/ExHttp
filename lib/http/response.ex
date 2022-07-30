defmodule ExHttp.Http.Response do
  defstruct code: 200, status: "OK", headers: %{}, cookies: [], body: ""

  @type t :: %ExHttp.Http.Response{
    code: integer,
    status: String.t,
    headers: %{String.t => String.t},
    cookies: [Backend.Http.Cookie.t],
    body: String.t
  }

  @type status :: :bad_request | :not_found | :internal

  @spec from_status(status) :: Backend.Http.Response.t()
  def from_status(:bad_request), do: bad_request()
  def from_status(:not_found), do: not_found()
  def from_status(:internal), do: internal_error()
  def from_status code do
    IO.puts "Unknown code '#{code}'"
    internal_error()
  end

  @spec add_header(t, String.t, String.t) :: t
  def add_header self, key, val do
    headers = Map.put self.headers, key, val
    %__MODULE__{ self | headers: headers }
  end

  @spec content_type(t, String.t) :: t
  def content_type self, type do
    add_header self, "Content-Type", type
  end

  defp bad_request do
    %__MODULE__{
      code: 400,
      status: "Bad Request",
      body: "400 Bad Request"
    }
  end

  defp not_found do
    %__MODULE__{
      code: 404,
      status: "NOT FOUND",
      body: "404 Not Found"
    }
  end

  defp internal_error do
    %__MODULE__{
      code: 500,
      status: "INTERNAL ERROR",
      body: "500 Internal Error"
    }
  end
end

defimpl String.Chars, for: ExHttp.Http.Response do
  def to_string self do
    resp = "HTTP/1.1 #{self.code} #{self.status}\r\n"
    headers = Map.to_list self.headers
    resp = List.foldl headers, resp, fn { name, val }, resp -> resp <> "#{name}: #{val}\r\n" end

    resp = List.foldl self.cookies, resp, fn cookie, resp -> resp <> "Set-Cookie: " <> Kernel.to_string(cookie) <> "\r\n" end

    if self.body && self.body !== "" do
      resp <> "Content-Length: #{String.length self.body}\r\n\r\n" <> self.body
    else
      resp <> "\r\n"
    end
  end
end
