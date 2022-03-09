defmodule LightningGraph.Lnd.GraphDownloader.Nodes do
  def to_csv(nodes, csv_file_path) do
    {:ok, file} = File.open(csv_file_path, [:write])
    write_nodes_header(file)
    nodes |> Enum.each(fn node -> node |> write_node(file) end)
    file |> File.close()
  end

  defp write_nodes_header(file) do
    IO.binwrite(file, "\"pub_key\",\"alias\",\"color\"\n")
  end

  defp write_node(node, file) do
    IO.binwrite(
      file,
      "#{node["pub_key"] |> inspect},#{node["alias"] |> inspect},#{node["color"] |> inspect}\n"
    )
  end
end
