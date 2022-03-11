defmodule LightningGraph.Neo4j.Lnd.GraphUpdater do
  use GenServer

  require Logger

  def start_link(_) do
    GenServer.start_link(__MODULE__, nil, name: __MODULE__)
  end

  def stop(reason \\ :normal, timeout \\ :infinity) do
    GenServer.stop(__MODULE__, reason, timeout)
  end

  def init(_) do
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

    {:ok, nil}
  end

  def handle_info(%Lnrpc.GraphTopologyUpdate{} = graph_topology_update, state) do
    now = DateTime.utc_now() |> DateTime.to_string()

    IO.puts("--graph-topology-update----#{now}---")

    graph_topology_update
    |> maybe_channel_updates
    |> maybe_closed_chans
    |> maybe_node_updates

    {:noreply, state}
  end

  def handle_info(event, state) do
    IO.puts("--------- got an unknown event")
    IO.inspect(event)

    {:noreply, state}
  end

  defp maybe_channel_updates(
         %Lnrpc.GraphTopologyUpdate{channel_updates: channel_updates} = graph_topology_update
       ) do
    channel_updates
    |> Enum.each(fn channel_update ->
      LightningGraph.Neo4j.get_connection()
      |> LightningGraph.Neo4j.Lnd.Mutations.Channel.update(channel_update)
    end)

    graph_topology_update
  end

  defp maybe_closed_chans(
         %Lnrpc.GraphTopologyUpdate{closed_chans: closed_chans} = graph_topology_update
       ) do
    closed_chans
    |> Enum.each(&IO.inspect/1)

    graph_topology_update
  end

  defp maybe_node_updates(
         %Lnrpc.GraphTopologyUpdate{node_updates: node_updates} = graph_topology_update
       ) do
    node_updates
    |> Enum.each(fn node_update ->
      LightningGraph.Neo4j.get_connection()
      |> LightningGraph.Neo4j.Lnd.Mutations.Node.update(node_update)
    end)

    graph_topology_update
  end
end
