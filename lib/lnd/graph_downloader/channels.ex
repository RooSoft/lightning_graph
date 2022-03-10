defmodule LightningGraph.Lnd.GraphDownloader.Channels do
  def to_csv(edges, csv_file_path) do
    {:ok, file} = File.open(csv_file_path, [:write])
    write_channels_header(file)

    edges
    |> Enum.each(fn edge ->
      write_channel(file, edge, "node1_pub", "node2_pub", edge["node1_policy"])
    end)

    edges
    |> Enum.each(fn edge ->
      write_channel(file, edge, "node2_pub", "node1_pub", edge["node2_policy"])
    end)

    file |> File.close()
  end

  defp write_channels_header(file) do
    header =
      get_channels_header()
      |> Enum.join(",")

    IO.binwrite(file, header)
    IO.write(file, "\n")
  end

  defp write_channel(file, edge, source_node_pub, destination_node_pub, policy) do
    channel = get_channel(edge, source_node_pub, destination_node_pub, policy)

    IO.binwrite(file, channel)
    IO.write(file, "\n")
  end

  defp get_channels_header() do
    [
      "channel_id" |> Kernel.inspect(),
      "node1_pub" |> Kernel.inspect(),
      "node2_pub" |> Kernel.inspect(),
      "capacity" |> Kernel.inspect(),
      "base_fee" |> Kernel.inspect(),
      "fee_rate" |> Kernel.inspect(),
      "is_disabled" |> Kernel.inspect()
    ]
  end

  defp get_channel(edge, source_node_pub, destination_node_pub, nil = _policy) do
    "\"#{edge["channel_id"]}\",\"#{edge[source_node_pub]}\",\"#{edge[destination_node_pub]}\",#{edge["capacity"]},0,0,0"
  end

  defp get_channel(edge, source_node_pub, destination_node_pub, policy) do
    disabled =
      case policy["disabled"] do
        true -> 1
        _ -> 0
      end

    "\"#{edge["channel_id"]}\",\"#{edge[source_node_pub]}\",\"#{edge[destination_node_pub]}\",#{edge["capacity"]},#{policy["fee_base_msat"]},#{policy["fee_rate_milli_msat"]},#{disabled}"
  end
end
