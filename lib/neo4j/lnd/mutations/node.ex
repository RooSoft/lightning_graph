defmodule LightningGraph.Neo4j.Lnd.Mutations.Node do
  require Logger

  def update(conn, node_update) do
    query = """
    MATCH (n:node {pub_key:"#{node_update.identity_key}"})
    SET n += {
      alias: "#{node_update.alias}",
      color: "#{node_update.color}",
      updated: "#{DateTime.utc_now() |> DateTime.to_string()}"
    }
    RETURN n;
    """

    Bolt.Sips.query!(conn, query)

    %{
      pub_key: node_update.identity_key,
      alias: node_update.alias,
      color: node_update.color
    }
  end
end
