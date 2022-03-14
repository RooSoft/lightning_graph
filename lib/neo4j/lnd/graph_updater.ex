defmodule LightningGraph.Neo4j.Lnd.GraphUpdater do
  use GenServer

  require Logger

  def start_link(_) do
    GenServer.start_link(__MODULE__, %{subscribers: []}, name: __MODULE__)
  end

  def stop(reason \\ :normal, timeout \\ :infinity) do
    GenServer.stop(__MODULE__, reason, timeout)
  end

  def init(arg) do
    LndClient.start()

    node_uri = System.get_env("NODE") || "localhost:10009"
    cert_path = System.get_env("CERT") || "~/.lnd/lnd.cert"
    macaroon_path = System.get_env("MACAROON") || "~/.lnd/readonly.macaroon"

    case LndClient.connect(node_uri, cert_path, macaroon_path) do
      {:ok, _state} ->
        LndClient.subscribe_channel_graph(%{pid: self()})

      {:error, error} ->
        Logger.warn("LndClient can't start")
        IO.inspect(error)

        :error
    end

    {:ok, arg}
  end

  def subscribe() do
    GenServer.call(__MODULE__, {:subscribe, self()})
  end

  def handle_call({:subscribe, pid}, _from, state) do
    {
      :reply,
      :ok,
      state
      |> Map.put(:subscribers, [pid | state.subscribers])
    }
  end

  def handle_info(%Lnrpc.GraphTopologyUpdate{} = graph_topology_update, state) do
    subscribers = state.subscribers

    graph_topology_update
    |> maybe_channel_updates(subscribers)
    |> maybe_closed_chans(subscribers)
    |> maybe_node_updates(subscribers)

    {:noreply, state}
  end

  def handle_info(event, state) do
    IO.puts("--------- got an unknown event")
    IO.inspect(event)

    {:noreply, state}
  end

  defp maybe_channel_updates(
         %Lnrpc.GraphTopologyUpdate{channel_updates: channel_updates} = graph_topology_update,
         subscribers
       ) do
    channel_updates
    |> Enum.each(fn channel_update ->
      LightningGraph.Neo4j.get_connection()
      |> LightningGraph.Neo4j.Lnd.Mutations.Channel.update(channel_update)
      |> send_to_subscribers(subscribers, :channel_update)
    end)

    graph_topology_update
  end

  defp maybe_closed_chans(
         %Lnrpc.GraphTopologyUpdate{closed_chans: closed_chans} = graph_topology_update,
         _subscribers
       ) do
    closed_chans
    |> Enum.each(&IO.inspect/1)

    graph_topology_update
  end

  defp maybe_node_updates(
         %Lnrpc.GraphTopologyUpdate{node_updates: node_updates} = graph_topology_update,
         subscribers
       ) do
    node_updates
    |> Enum.each(fn node_update ->
      LightningGraph.Neo4j.get_connection()
      |> LightningGraph.Neo4j.Lnd.Mutations.Node.update(node_update)
      |> send_to_subscribers(subscribers, :node_update)
    end)

    graph_topology_update
  end

  defp send_to_subscribers(payload, subscribers, topic) do
    subscribers
    |> Enum.each(fn subscriber ->
      send(subscriber, {:graph_updater, topic, payload})
    end)
  end
end
