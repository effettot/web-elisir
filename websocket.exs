defmodule ChatServer do
  require Logger

  def start do
    Logger.info("Avviando il ChatServer...")
    {:ok, _} = Plug.Adapters.Cowboy.http(__MODULE__, [])
  end

  def init(_) do
    Phoenix.Endpoint.CowboyWebSocket.init(
      dispatcher: __MODULE__,
      protocols: [:websocket],
      handler: __MODULE__
    )
  end

  def handle_in("join", _params, socket) do
    Logger.info("L'utente e entrato nella chat")
    {:ok, assign(socket, :joined, true)}
  end

  def handle_in("message", %{"text" => message}, socket) do
    Logger.info("Messaggio ricevuto: #{message}")
    broadcast(socket, "message", %{text: message})
    {:noreply, socket}
  end

  def handle_out("message", payload, socket) do
    push(socket, "message", payload)
    {:ok, socket}
  end

  def handle_cast(_msg, state) do
    {:noreply, state}
  end

  def handle_info(_msg, state) do
    {:noreply, state}
  end

  defp broadcast(socket, event, payload) do
    Enum.each(get_clients(socket), fn client ->
      push(client, event, payload)
    end)
  end

  defp push(socket, event, payload) do
    Phoenix.Socket.broadcast!(socket, event, payload)
  end

  defp get_clients(socket) do
    Phoenix.Channel.list(socket)
    |> Enum.filter(&(&1 != socket))
  end
end
