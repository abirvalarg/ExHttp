defmodule ExHttp do
  use GenServer

  defstruct socket: nil, router: nil

  @type args :: [
    host: :inet.socket_address,
    port: :inet.port_number,
    router: any()
  ]

  def start_link args do
    GenServer.start_link __MODULE__, args, name: __MODULE__
  end

  @impl true
  def init args do
    host = args[:host] || :any
    port = args[:port] || 8080
    router = args[:router]

    { :ok, socket } = open_socket host, port

    IO.puts "Server started at http://#{show_host host}:#{port}"
    send self(), :accept

    { :ok, %__MODULE__{ socket: socket, router: router } }
  end

  @impl true
  def handle_info :accept, state do
    with { :ok, client } <- :gen_tcp.accept(state.socket, 1000) do
      { :ok, pid } = GenServer.start ExHttp.Handler, [ client: client, router: state.router ]
      :gen_tcp.controlling_process client, pid
    end
    send self(), :accept
    { :noreply, state }
  end

  @impl true
  def handle_cast :stop, state do
    { :stop, :normal, state }
  end

  @impl true
  def terminate _type, state do
    :gen_tcp.close state.socket
  end

  @spec show_host(:inet.socket_address()) :: String.t
  defp show_host(:any), do: "0.0.0.0"
  defp show_host(:loopback), do: "127.0.0.1"
  defp show_host({ a, b, c, d }), do: "#{a}.#{b}.#{c}.#{d}"

  defp open_socket host, port, show_msg \\ true do
    with { :ok, socket } <- :gen_tcp.listen(port, [ :binary, ip: host ]) do
      { :ok, socket }
    else
      { :error, :eaddrinuse } ->
        if show_msg do
          IO.puts "Waiting for the address to be available"
        end
        :timer.sleep 1000
        open_socket host, port, false
      other -> other
    end
  end
end
