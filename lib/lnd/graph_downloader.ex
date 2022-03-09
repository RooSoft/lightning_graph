defmodule LightningGraph.Lnd.GraphDownloader do
  alias LightningGraph.Lnd.GraphDownloader.Channels
  alias LightningGraph.Lnd.GraphDownloader.Nodes

  def get(cert, macaroon, url, nodes_csv_file_path, channels_csv_file_path) do
    graph = get_graph(cert, macaroon, url) |> Jason.decode!()

    graph["nodes"]
    |> Enum.filter(fn node -> node["last_update"] > 0 end)
    |> Nodes.to_csv(nodes_csv_file_path)

    graph["edges"]
    |> Enum.filter(fn edge -> edge["last_update"] > 0 end)
    |> Channels.to_csv(channels_csv_file_path)
  end

  defp get_headers(macaroon_filename) do
    [
      {'Grpc-Metadata-macaroon', macaroon_filename |> read_macaroon |> to_charlist}
    ]
  end

  defp read_macaroon(macaroon_filename) do
    File.read!(macaroon_filename) |> Base.encode16()
  end

  defp get_options(cert_filename) do
    [ssl: [cacertfile: cert_filename]]
  end

  defp get_graph(cert_filename, macaroon_filename, url) do
    headers = get_headers(macaroon_filename)
    request = {String.to_charlist(url), headers}
    options = get_options(cert_filename)

    case :httpc.request(:get, request, options, []) do
      {:ok, {{_v, 200, _m}, _h, body}} -> :erlang.list_to_binary(body)
    end
  end
end
